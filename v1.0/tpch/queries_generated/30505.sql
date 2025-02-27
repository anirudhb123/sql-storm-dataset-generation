WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey,
           CAST(s_name AS VARCHAR(255)) AS full_name,
           1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           CONCAT(sh.full_name, ' -> ', s.s_name) AS full_name,
           level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
total_orders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM orders o 
    GROUP BY o.o_custkey
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, tc.total_spent
    FROM customer c
    JOIN total_orders tc ON c.c_custkey = tc.o_custkey
    WHERE tc.total_spent > 10000
),
lineitem_summary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
ranked_lineitems AS (
    SELECT l.*, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS lineitem_rank
    FROM lineitem l
),
average_revenue AS (
    SELECT AVG(total_revenue) AS average_revenue
    FROM lineitem_summary
)

SELECT s.full_name, 
       s.level, 
       h.c_custkey, 
       h.c_name, 
       h.c_acctbal,
       lr.total_revenue,
       ar.average_revenue
FROM supplier_hierarchy s
LEFT JOIN high_value_customers h ON s.s_nationkey = h.c_nationkey
LEFT JOIN (SELECT l_orderkey, SUM(l_extendedprice) AS total_revenue 
           FROM ranked_lineitems 
           WHERE lineitem_rank = 1
           GROUP BY l_orderkey) lr ON lr.l_orderkey = h.c_custkey
CROSS JOIN average_revenue ar
WHERE h.c_acctbal IS NOT NULL 
AND (s.s_acctbal - COALESCE(h.c_acctbal, 0)) > 0
ORDER BY s.level, h.c_name;
