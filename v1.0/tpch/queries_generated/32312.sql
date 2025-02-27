WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierSales AS (
    SELECT sh.s_suppkey, SUM(od.total_sales) AS total_sales
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN OrderDetails od ON ps.ps_partkey = od.o_orderkey
    GROUP BY sh.s_suppkey
)
SELECT r.r_name, n.n_name, COALESCE(ss.total_sales, 0) AS total_sales,
       CASE 
           WHEN COALESCE(ss.total_sales, 0) > 100000 THEN 'High Performer'
           WHEN COALESCE(ss.total_sales, 0) BETWEEN 50000 AND 100000 THEN 'Moderate Performer'
           ELSE 'Low Performer'
       END AS performance_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierSales ss ON n.n_nationkey = ss.s_suppkey
WHERE (r.r_name LIKE '%West%' OR r.r_name LIKE '%East%')
AND (ss.total_sales IS NULL OR ss.total_sales > 0)
ORDER BY total_sales DESC
LIMIT 10;
