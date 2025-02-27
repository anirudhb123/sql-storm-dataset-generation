WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(l.l_orderkey) AS item_count, 
           RANK() OVER (PARTITION BY l.l_returnflag ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
)
SELECT r.r_name, 
       COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       SUM(os.total_sales) AS total_sales,
       AVG(os.total_sales) AS avg_sales_per_order,
       COUNT(DISTINCT os.o_orderkey) AS order_count,
       MAX(os.total_sales) AS max_sales,
       MIN(os.total_sales) AS min_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN order_summary os ON sh.s_suppkey = os.o_orderkey
WHERE (os.total_sales IS NOT NULL OR n.n_regionkey IS NULL)
AND (os.total_sales > 1000 OR sh.level = 0)
GROUP BY r.r_name, supplier_name
HAVING COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY total_sales DESC
LIMIT 10;
