WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.order_count, c.total_spent,
           RANK() OVER (ORDER BY c.total_spent DESC) AS spend_rank
    FROM customer_orders c
    WHERE c.total_spent IS NOT NULL AND c.order_count > 0
),
popular_parts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > (
        SELECT AVG(l2.l_quantity) FROM lineitem l2
        WHERE l2.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 YEAR' AND CURRENT_DATE
    )
)
SELECT 
    s.s_name, 
    s.s_nationkey,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    pp.p_name,
    pp.total_quantity,
    AVERAGE(l.l_discount) AS avg_discount,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY o.o_totalprice) AS "90th Percentile Price"
FROM supplier_hierarchy s
FULL OUTER JOIN top_customers c ON s.s_nationkey = c.c_custkey
LEFT JOIN popular_parts pp ON pp.total_quantity IN (
    SELECT total_quantity FROM popular_parts pp1 WHERE pp1.total_quantity IS NULL
)
LEFT JOIN lineitem l ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1)
LEFT JOIN orders o ON o.o_orderkey IN (
    SELECT o2.o_orderkey FROM orders o2 
    WHERE o2.o_orderdate < CURRENT_DATE 
    AND EXISTS (
        SELECT NULL FROM lineitem l2 WHERE l2.l_orderkey = o2.o_orderkey AND l2.l_returnflag = 'R'
    )
)
WHERE s.level < 3
AND COALESCE(pp.total_quantity, 0) > 100
GROUP BY s.s_name, s.s_nationkey, c.c_name, pp.p_name, pp.total_quantity
ORDER BY s.s_name, c.order_count DESC NULLS LAST;
