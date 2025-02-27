WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level 
    FROM nation
    WHERE n_nationkey = (SELECT MIN(nation.n_nationkey) FROM nation)  
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1 
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           RANK() OVER (PARTITION BY ps.ps_suppkey ORDER BY p.p_retailprice DESC) as part_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10
),
total_orders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) as total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, t.total_spent
    FROM customer c
    JOIN total_orders t ON c.c_custkey = t.o_custkey
    WHERE t.total_spent > (SELECT AVG(total_spent) FROM total_orders) 
)
SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
       SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS available_quantity,
       SUM(COALESCE(lp.l_extendedprice, 0) * (1 - lp.l_discount)) AS total_revenue,
       STRING_AGG(DISTINCT rp.p_name, ', ') AS part_names
FROM supplier s
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem lp ON ps.ps_partkey = lp.l_partkey
LEFT JOIN ranked_parts rp ON ps.ps_partkey = rp.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN high_value_customers hvc ON hvc.c_custkey = s.s_nationkey
WHERE s.s_acctbal IS NOT NULL
GROUP BY n.n_name
HAVING SUM(COALESCE(lp.l_quantity, 0)) > 1000
ORDER BY total_revenue DESC;