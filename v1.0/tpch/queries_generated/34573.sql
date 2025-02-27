WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
),
total_order_values AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_custkey
),
customer_ranking AS (
    SELECT c.c_custkey, c.c_name, t.total_value,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY t.total_value DESC) AS cust_rank
    FROM customer c
    LEFT JOIN total_order_values t ON c.c_custkey = t.o_custkey
)
SELECT c.c_name, r.r_name, COALESCE(cr.total_value, 0) AS total_value, cr.cust_rank
FROM customer_ranking cr
JOIN nation n ON cr.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE cr.cust_rank <= 10
  AND (r.r_comment LIKE '%north%' OR r.r_comment IS NULL)
ORDER BY r.r_name, cr.total_value DESC;
