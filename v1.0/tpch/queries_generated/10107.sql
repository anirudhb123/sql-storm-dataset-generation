WITH part_summary AS (
    SELECT p_partkey, p_name, SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM part
    JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
    GROUP BY p_partkey, p_name
),
customer_summary AS (
    SELECT c_custkey, c_name, COUNT(o_orderkey) AS total_orders
    FROM customer
    LEFT JOIN orders ON customer.c_custkey = orders.o_custkey
    GROUP BY c_custkey, c_name
)
SELECT ps.p_partkey, ps.p_name, cs.c_custkey, cs.c_name, ps.total_supply_cost, cs.total_orders
FROM part_summary ps
JOIN customer_summary cs ON ps.total_supply_cost > 1000000 AND cs.total_orders > 5
ORDER BY ps.total_supply_cost DESC, cs.total_orders DESC
LIMIT 100;
