WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.c_name,
        r.total_sales,
        COALESCE(sd.total_supply_cost, 0) AS supply_cost
    FROM 
        RankedOrders r
    LEFT JOIN 
        SupplierDetails sd ON r.total_sales > 1000
    WHERE 
        r.order_rank = 1
),
FinalResults AS (
    SELECT 
        h.c_name,
        h.total_sales,
        h.supply_cost,
        CASE 
            WHEN h.supply_cost > 5000 THEN 'High Cost Supplier'
            ELSE 'Regular Supplier'
        END AS supplier_category
    FROM 
        HighValueOrders h
    WHERE 
        h.total_sales IS NOT NULL
    ORDER BY 
        h.total_sales DESC
)
SELECT 
    f.c_name,
    f.total_sales,
    f.supply_cost,
    f.supplier_category,
    CONCAT('Customer ', f.c_name, ' has total sales of ', f.total_sales) AS sales_statement,
    NULLIF(f.supply_cost, 0) AS adjusted_supply_cost
FROM 
    FinalResults f
WHERE 
    f.supplier_category = 'High Cost Supplier' OR f.total_sales > 2000
ORDER BY 
    f.total_sales DESC;
