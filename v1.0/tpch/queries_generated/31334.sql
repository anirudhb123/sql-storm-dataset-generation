WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty < 100 AND p.p_size > 30
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > (SELECT AVG(total_spent) FROM (
        SELECT SUM(o_totalprice) AS total_spent 
        FROM orders 
        GROUP BY o_custkey) AS average_spent)
),
part_supplier_data AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    c.c_name AS customer_name,
    sh.level AS supplier_level,
    p.p_name AS part_name,
    ps.total_supply_value,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY ps.total_supply_value DESC) AS rank
FROM customer_orders co
JOIN customer c ON co.c_custkey = c.c_custkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
JOIN part_supplier_data ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sh.s_suppkey)
WHERE c.c_acctbal IS NOT NULL
ORDER BY c.c_name, sh.level, ps.total_supply_value DESC;
