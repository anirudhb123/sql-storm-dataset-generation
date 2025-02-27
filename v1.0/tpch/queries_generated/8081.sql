WITH aggregated_costs AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), nation_supplier_sum AS (
    SELECT n.n_nationkey, SUM(s.s_acctbal) AS total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cs.c_custkey) AS unique_customers,
    SUM(ac.total_cost) AS sum_part_costs,
    SUM(cs.total_spent) AS sum_customer_spending,
    SUM(ns.total_balance) AS sum_nation_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer_orders cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN aggregated_costs ac ON ac.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = n.n_nationkey)
LEFT JOIN nation_supplier_sum ns ON n.n_nationkey = ns.n_nationkey
GROUP BY r.r_name
ORDER BY r.r_name;
