
WITH RECURSIVE order_hierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
    WHERE o.o_orderstatus = 'O'
),
supplier_parts AS (
    SELECT ps_partkey, s.s_nationkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps_partkey, s.s_nationkey
),
customer_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
ranked_customers AS (
    SELECT c_nationkey, order_count, total_spent,
           RANK() OVER (PARTITION BY c_nationkey ORDER BY total_spent DESC) AS rank
    FROM customer_summary
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(rs.order_count, 0) AS customer_order_count,
    COALESCE(rs.total_spent, 0) AS customer_total_spent,
    COALESCE(SUM(sp.total_cost), 0) AS supplier_parts_total_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN ranked_customers rs ON n.n_nationkey = rs.c_nationkey
LEFT JOIN supplier_parts sp ON n.n_nationkey = sp.s_nationkey
GROUP BY r.r_name, n.n_name, rs.order_count, rs.total_spent
HAVING COALESCE(SUM(sp.total_cost), 0) > 10000
ORDER BY r.r_name, n.n_name;
