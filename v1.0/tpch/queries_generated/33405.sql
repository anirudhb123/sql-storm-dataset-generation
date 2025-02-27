WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
      AND level < 5
),
customer_details AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, c.c_mktsegment,
            ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rn
    FROM customer c
    WHERE c.c_acctbal > 1000.00
),
lineitem_summary AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_quantity) AS total_quantity,
           AVG(l.l_discount) AS avg_discount, 
           COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
),
order_analysis AS (
    SELECT o.o_orderkey, o.o_orderstatus,
           CASE WHEN l.total_quantity > 100 THEN 'High' ELSE 'Low' END AS quantity_class,
           l.avg_discount
    FROM orders o
    LEFT JOIN lineitem_summary l ON o.o_orderkey = l.l_orderkey
)
SELECT r.r_name, SUM(o.o_totalprice) AS total_revenue,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       MAX(sh.level) AS max_supplier_level,
       STRING_AGG(DISTINCT c.c_mktsegment, '; ') AS marketing_segments
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
JOIN customer_details c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN order_analysis oa ON o.o_orderkey = oa.o_orderkey
WHERE c.c_acctbal IS NOT NULL
  AND r.r_name NOT LIKE '%East%'
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC;
