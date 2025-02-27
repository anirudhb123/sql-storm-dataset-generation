WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS hierarchy_level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.hierarchy_level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_custkey = c.c_custkey
    WHERE ch.hierarchy_level < 5
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_suppliers AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
combined_data AS (
    SELECT ch.c_custkey, ch.c_name, n.n_name AS nation_name, o.total_sales, o.sales_rank
    FROM customer_hierarchy ch
    LEFT JOIN ranked_orders o ON ch.c_custkey = o.o_custkey
    LEFT JOIN nation n ON ch.c_nationkey = n.n_nationkey
)
SELECT cd.c_custkey, cd.c_name, cd.nation_name,
       COALESCE(cd.total_sales, 0) AS adjusted_total_sales,
       CASE 
           WHEN cd.sales_rank IS NULL THEN 'No Orders'
           WHEN cd.sales_rank <= 5 THEN 'Top 5'
           ELSE 'Others'
       END AS sales_category,
       SUBSTRING(cd.nation_name, 1, 3) || '-' || LPAD(cd.c_custkey::text, 5, '0') AS customer_id_tag
FROM combined_data cd
WHERE (cd.adjusted_total_sales > 50 OR cd.nation_name IS NOT NULL)
  AND (cd.nation_name NOT LIKE '%land' OR cd.total_sales IS NULL)
ORDER BY cd.adjusted_total_sales DESC
LIMIT 100
OFFSET (SELECT COUNT(DISTINCT c_custkey) FROM customer) % 50;
