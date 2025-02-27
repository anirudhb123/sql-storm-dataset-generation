
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderStats AS (
    SELECT o.o_orderkey, 
           COUNT(DISTINCT l.l_linenumber) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
AvgSales AS (
    SELECT AVG(total_sales) AS avg_total_sales 
    FROM OrderStats
),
SupplierSales AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_total_sales
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name, 
       s.s_name AS supplier_name,
       COALESCE(ss.supplier_total_sales, 0) AS total_sales,
       CASE 
           WHEN ss.supplier_total_sales IS NULL THEN 'No Sales'
           WHEN ss.supplier_total_sales > a.avg_total_sales THEN 'Above Average'
           ELSE 'Below Average'
       END AS sales_comparison,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(ss.supplier_total_sales, 0) DESC) AS sales_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
CROSS JOIN AvgSales a
WHERE r.r_name IS NOT NULL
ORDER BY r.r_name, sales_rank;
