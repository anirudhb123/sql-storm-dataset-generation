WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY s.s_suppkey, s.s_name
),
AggregatedSales AS (
    SELECT 
        s.s_suppkey,
        s.total_sales,
        s.order_count,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS sales_rank,
        COALESCE(AVG(s.total_sales) OVER (), 0) AS avg_total_sales
    FROM SupplierSales s
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(a.total_sales, 0) AS total_sales,
    a.order_count,
    CASE 
        WHEN a.total_sales > a.avg_total_sales THEN 'Above Average'
        WHEN a.total_sales < a.avg_total_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_comparison
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN AggregatedSales a ON n.n_nationkey = a.s_suppkey
WHERE n.n_nationkey IN (SELECT n_nationkey FROM NationHierarchy)
ORDER BY r.r_name, total_sales DESC;
