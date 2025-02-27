WITH part_supplier AS (
    SELECT p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost, ps.ps_availqty, ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
customers AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
top_customers AS (
    SELECT c.c_name, c.order_count
    FROM customers c
    WHERE c.order_count > (SELECT AVG(order_count) FROM customers)
),
final_results AS (
    SELECT ps.p_partkey, ps.p_name, ps.s_name, ps.ps_supplycost, ps.ps_availqty, tc.c_name AS top_customer_name
    FROM part_supplier ps
    JOIN top_customers tc ON ps.rn = 1
)
SELECT p.p_partkey, p.p_name, p.s_name, p.ps_supplycost, p.ps_availqty, p.top_customer_name
FROM final_results p
WHERE p.ps_availqty > 50
ORDER BY p.ps_supplycost DESC, p.p_name;
