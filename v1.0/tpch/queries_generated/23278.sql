WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 
           CAST(s_name AS VARCHAR(100)) AS hierarchy_path, 
           1 AS level
    FROM supplier
    WHERE s_suppkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           CONCAT(sh.hierarchy_path, ' > ', s.s_name),
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) 
                         FROM customer c2 
                         WHERE c2.c_mktsegment = c.c_mktsegment)
),
line_item_summary AS (
    SELECT l.l_orderkey, 
           COUNT(l.l_linenumber) AS total_items,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY l.l_orderkey
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(ls.total_revenue) AS total_revenue,
       MAX(CASE WHEN ls.total_items > 5 THEN 'High' ELSE 'Low' END) AS item_category,
       COALESCE(STRING_AGG(DISTINCT CONCAT(sh.hierarchy_path, ' (', s.s_name, ')'), ', '), 'No Suppliers') AS supplier_chain
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN customer_orders co ON c.c_custkey = co.c_custkey AND co.order_rank = 1
LEFT JOIN orders o ON o.o_orderkey = co.o_orderkey
LEFT JOIN line_item_summary ls ON ls.l_orderkey = o.o_orderkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN supplier s ON sh.s_suppkey = s.s_suppkey
WHERE r.r_name IS NOT NULL AND n.n_comment IS NOT NULL
GROUP BY r.r_name
HAVING SUM(ls.total_revenue) > 10000 OR COUNT(DISTINCT c.c_custkey) > 20
ORDER BY total_revenue DESC, customer_count ASC;
