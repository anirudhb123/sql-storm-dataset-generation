
WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 100
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supply_chain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE ps.ps_availqty < 100
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY c.c_custkey, c.c_name
),
ranked_orders AS (
    SELECT co.c_custkey, co.c_name, co.total_spent,
           RANK() OVER (ORDER BY co.total_spent DESC) AS spend_rank
    FROM customer_orders co
)
SELECT r.r_name, COUNT(DISTINCT ro.c_custkey) AS customer_count,
       AVG(ro.total_spent) AS avg_spent,
       SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN ranked_orders ro ON ro.c_custkey = s.s_suppkey
WHERE ro.spend_rank <= 10 OR ro.c_custkey IS NULL
GROUP BY r.r_name
HAVING SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL AND AVG(ro.total_spent) > 1000
ORDER BY r.r_name;
