WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        hs.s_suppkey, 
        hs.s_name, 
        hs.total_cost
    FROM 
        RankedSuppliers hs
    WHERE 
        hs.rank <= 5
),
TotalOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
SupplierPerformance AS (
    SELECT 
        hs.s_suppkey, 
        COUNT(DISTINCT o.o_orderkey) as order_count,
        AVG(to.total_revenue) as avg_revenue
    FROM 
        HighCostSuppliers hs
    LEFT JOIN 
        partsupp ps ON hs.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        hs.s_suppkey
),
FinalReport AS (
    SELECT 
        sp.s_suppkey, 
        COALESCE(sp.order_count, 0) AS order_count, 
        COALESCE(sp.avg_revenue, 0) AS avg_revenue,
        CASE 
            WHEN sp.avg_revenue > 10000 THEN 'High Performer'
            WHEN sp.avg_revenue BETWEEN 5000 AND 10000 THEN 'Medium Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM 
        HighCostSuppliers hs
    LEFT JOIN 
        SupplierPerformance sp ON hs.s_suppkey = sp.s_suppkey
)
SELECT 
    fr.s_suppkey, 
    fr.order_count, 
    fr.avg_revenue, 
    fr.performance_category,
    (SELECT COUNT(*) FROM nation) AS total_nations,
    (SELECT COUNT(*) FROM region) AS total_regions
FROM 
    FinalReport fr
WHERE 
    fr.order_count IS NOT NULL
ORDER BY 
    fr.avg_revenue DESC
LIMIT 10;
