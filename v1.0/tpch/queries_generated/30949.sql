WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 100)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        RANK() OVER (PARTITION BY l.l_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT 
        sh.s_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(ts.total_sales) AS total_sales
    FROM SupplierHierarchy sh
    LEFT JOIN TotalSales ts ON sh.s_suppkey = ts.l_suppkey
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY sh.s_suppkey
)
SELECT 
    s.s_name,
    COALESCE(ss.order_count, 0) AS order_count,
    COALESCE(ss.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(ss.total_sales, 0) > 10000 THEN 'High Performer'
        WHEN COALESCE(ss.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM supplier s
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE s.s_acctbal IS NOT NULL
ORDER BY performance_category DESC, total_sales DESC;
