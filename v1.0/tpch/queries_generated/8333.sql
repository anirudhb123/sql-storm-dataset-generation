WITH RECURSIVE recent_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN recent_orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, cs.total_orders, cs.total_spent
    FROM customer_summary cs
    JOIN customer c ON cs.c_custkey = c.c_custkey
    WHERE cs.total_spent > (
        SELECT AVG(total_spent) FROM customer_summary
    )
    ORDER BY cs.total_orders DESC
    LIMIT 10
)

SELECT c.c_name, p.p_name, ps.ps_availqty, ps.ps_supplycost
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN top_customers tc ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (
    SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = tc.c_custkey
))
ORDER BY p.p_name, s.s_name;
