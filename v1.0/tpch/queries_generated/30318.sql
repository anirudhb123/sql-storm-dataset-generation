WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
ranked_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT DISTINCT sh.s_name, ps.p_name, cs.total_spent, ps.avg_supplycost,
       CASE 
           WHEN cs.order_count > 10 THEN 'High Value'
           WHEN cs.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
           ELSE 'Low Value' 
       END AS customer_value_segment
FROM supplier_hierarchy sh
JOIN part_summary ps ON sh.s_nationkey = ps.p_partkey % 10
JOIN customer_orders cs ON cs.total_spent > ps.avg_supplycost * 100
WHERE sh.level BETWEEN 1 AND 3
ORDER BY cs.total_spent DESC, ps.p_name ASC
LIMIT 50;
