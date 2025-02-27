WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE sh.level < 5
),

top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),

high_value_parts AS (
    SELECT p.p_partkey, p.p_name, MAX(ps.ps_supplycost) AS max_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING MAX(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),

customer_nations AS (
    SELECT c.c_custkey, n.n_nationkey, n.n_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)

SELECT 
    sh.s_name AS supplier_name,
    sh.s_acctbal AS supplier_balance,
    tc.total_spent,
    hp.p_name AS high_value_part,
    hp.max_supply_cost,
    COALESCE(cn.n_name, 'Unknown') AS customer_nation
FROM 
    supplier_hierarchy sh
LEFT JOIN 
    high_value_parts hp ON hp.max_supply_cost < sh.s_acctbal
JOIN 
    top_customers tc ON tc.total_spent > 1000
LEFT JOIN 
    customer_nations cn ON cn.c_custkey = tc.c_custkey
WHERE 
    sh.level = (SELECT MAX(level) FROM supplier_hierarchy)
    AND (sh.s_acctbal IS NOT NULL OR sh.s_acctbal > 0)
ORDER BY 
    sh.s_name, tc.total_spent DESC
LIMIT 10;
