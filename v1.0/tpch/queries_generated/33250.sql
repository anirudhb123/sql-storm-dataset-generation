WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
available_parts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
customer_order AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(COALESCE(os.total_revenue, 0)) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COUNT(DISTINCT cs.c_custkey) AS total_customers,
       SUM(COALESCE(cs.total_spent, 0)) AS total_revenue,
       SUM(COALESCE(ap.total_available, 0)) AS total_parts_available
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer_order cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN available_parts ap ON ap.avg_supply_cost < (SELECT AVG(avg_supply_cost) FROM available_parts)
WHERE cs.order_count > 1
GROUP BY r.r_name
HAVING SUM(COALESCE(cs.total_spent, 0)) > 10000
ORDER BY total_revenue DESC;
