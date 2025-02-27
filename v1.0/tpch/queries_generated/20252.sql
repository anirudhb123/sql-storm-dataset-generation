WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        COUNT(*) OVER (PARTITION BY s.s_nationkey) AS nation_count
    FROM supplier s
), FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_orderstatus
), HighValueSuppliers AS (
    SELECT 
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM RankedSuppliers s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.rank = 1 AND s.nation_count > 1
), TopOrders AS (
    SELECT 
        fo.o_orderkey, 
        fo.o_orderstatus,
        COALESCE(fo.total_revenue, 0) AS total_revenue,
        CASE 
            WHEN fo.o_orderstatus = 'O' AND coalesce(fo.total_revenue, 0) > 10000 THEN 'High'
            WHEN fo.o_orderstatus = 'F' AND coalesce(fo.total_revenue, 0) <= 10000 THEN 'Low'
            ELSE 'Medium' 
        END AS revenue_category
    FROM FilteredOrders fo
), SupplierStats AS (
    SELECT 
        h.s_name,
        COUNT(DISTINCT t.o_orderkey) AS order_count,
        SUM(t.total_revenue) AS revenue_sum,
        AVG(t.total_revenue) AS avg_revenue
    FROM HighValueSuppliers h
    LEFT JOIN TopOrders t ON h.s_suppkey = t.o_orderkey
    GROUP BY h.s_name
)
SELECT 
    s.s_name,
    s.order_count,
    s.revenue_sum,
    s.avg_revenue,
    CASE 
        WHEN s.avg_revenue IS NULL THEN 'No Revenue'
        WHEN s.avg_revenue > 5000 THEN 'High Performer'
        WHEN s.avg_revenue BETWEEN 1000 AND 5000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM SupplierStats s
WHERE s.order_count > 0
UNION ALL
SELECT 
    'TOTALS', 
    COUNT(*), 
    SUM(revenue_sum), 
    AVG(avg_revenue)
FROM SupplierStats
HAVING AVG(avg_revenue) IS NOT NULL
ORDER BY s_name;
