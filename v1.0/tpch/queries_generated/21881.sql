WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.level * 500
),
supplier_orders AS (
    SELECT s.s_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY s.s_name
),
filtered_orders AS (
    SELECT s.s_name,
           SUM(CASE 
                   WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) 
                   ELSE l.l_extendedprice 
               END) AS total_sales
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_name
),
final_summary AS (
    SELECT sh.s_name, 
           COALESCE(so.order_count, 0) AS order_count, 
           COALESCE(fo.total_sales, 0) AS total_sales,
           ROW_NUMBER() OVER (ORDER BY COALESCE(fo.total_sales, 0) DESC) AS rank
    FROM supplier_hierarchy sh
    LEFT JOIN supplier_orders so ON sh.s_name = so.s_name
    LEFT JOIN filtered_orders fo ON sh.s_name = fo.s_name
)
SELECT fs.s_name, fs.order_count, fs.total_sales, 
       CASE 
           WHEN fs.total_sales > 5000 THEN 'High'
           WHEN fs.total_sales BETWEEN 2000 AND 5000 THEN 'Medium'
           ELSE 'Low'
       END AS sales_category
FROM final_summary fs
WHERE fs.rank <= 10
ORDER BY fs.order_count DESC, fs.total_sales DESC
WITH TIES;
