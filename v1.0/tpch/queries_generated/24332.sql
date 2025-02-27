WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        MAX(ps.ps_supplycost) AS max_supplycost,
        MIN(ps.ps_supplycost) AS min_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count,
        MAX(o.o_orderdate) AS latest_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_order_value,
        ROW_NUMBER() OVER (PARTITION BY os.o_custkey ORDER BY os.total_order_value DESC) AS rank_within_customer
    FROM 
        OrderSummary os
    WHERE 
        os.total_order_value > (SELECT AVG(total_order_value) FROM OrderSummary)
),
SupplierDetails AS (
    SELECT 
        sc.supp_name,
        sc.total_supplycost,
        os.total_order_value,
        os.rank_within_customer,
        RANK() OVER (ORDER BY sc.total_supplycost DESC) AS supplier_rank
    FROM 
        SupplierCosts sc
    LEFT JOIN 
        HighValueOrders os ON sc.s_suppkey = os.o_custkey
    WHERE 
        sc.total_supplycost > (
            SELECT AVG(total_supplycost) FROM SupplierCosts
        )
)
SELECT 
    COALESCE(sd.supp_name, 'Unknown Supplier') AS supplier_name,
    sd.total_supplycost,
    sd.total_order_value,
    sd.rank_within_customer,
    sd.supplier_rank,
    CASE 
        WHEN sd.total_order_value IS NULL THEN 'No Orders'
        WHEN sd.total_supplycost < 1000 THEN 'Low Cost Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_category
FROM 
    SupplierDetails sd
WHERE 
    sd.rank_within_customer IS NOT NULL
ORDER BY 
    sd.supplier_rank,
    sd.total_supplycost DESC;
