WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c_acctbal)
        FROM customer
    )
    UNION ALL
    SELECT c2.c_custkey, c2.c_name, c2.c_nationkey, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c2 ON c2.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
aggregated_orders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
top_customers AS (
    SELECT ch.c_custkey, ch.c_name, ao.order_count, ao.total_spent
    FROM customer_hierarchy ch
    JOIN aggregated_orders ao ON ch.c_custkey = ao.o_custkey
    WHERE ao.total_spent > 1000
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.total_supply_cost,
           RANK() OVER (ORDER BY ps.total_supply_cost DESC) AS rank
    FROM part p
    JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
)
SELECT r.r_name, COUNT(DISTINCT tc.c_custkey) AS customer_count,
       AVG(rp.p_retailprice) AS avg_part_price,
       SUM(CASE 
           WHEN l.l_returnflag = 'Y' THEN 1 
           ELSE 0 END) AS total_returns
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN top_customers tc ON s.s_nationkey = tc.o_custkey
LEFT JOIN ranked_parts rp ON l.l_partkey = rp.p_partkey
WHERE rp.rank <= 10
GROUP BY r.r_name
HAVING AVG(rp.p_retailprice) IS NOT NULL
ORDER BY customer_count DESC, avg_part_price ASC;
