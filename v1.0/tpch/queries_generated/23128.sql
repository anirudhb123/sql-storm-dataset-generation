WITH RECURSIVE CustomerCTE AS (
    SELECT 
        c_custkey, 
        c_name, 
        c_nationkey, 
        c_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS rn
    FROM 
        customer
    WHERE 
        c_acctbal IS NOT NULL
), 
PartSupplierCTE AS (
    SELECT 
        ps_partkey, 
        SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS item_count,
        MAX(l.l_returnflag) AS max_returnflag
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), 
SupplierPerformance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COALESCE(MAX(r.r_name), 'Unknown') AS region_name, 
        SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
FinalOutput AS (
    SELECT 
        c.c_name,
        c.rn,
        sp.s_name, 
        sp.total_avail_qty,
        os.item_count, 
        os.revenue,
        CASE 
            WHEN os.revenue IS NULL THEN 'No Orders' 
            WHEN os.revenue > 10000 THEN 'High Revenue'
            ELSE 'Moderate Revenue'
        END AS revenue_category 
    FROM 
        CustomerCTE c
    JOIN 
        SupplierPerformance sp ON c.c_custkey = sp.s_suppkey
    LEFT JOIN 
        OrderSummary os ON os.o_orderkey = sp.s_suppkey
    WHERE 
        c.rn <= 5
)
SELECT 
    COALESCE(fo.c_name, 'N/A') AS customer_name,
    COALESCE(fo.s_name, 'No Supplier') AS supplier_name,
    COALESCE(fo.total_avail_qty, 0) AS available_quantity,
    COALESCE(fo.item_count, 0) AS completed_orders,
    COALESCE(fo.revenue, 0) AS total_revenue,
    fo.revenue_category
FROM 
    FinalOutput fo
ORDER BY 
    fo.customer_name ASC, fo.total_revenue DESC;
