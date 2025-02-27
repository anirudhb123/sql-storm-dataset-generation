WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    n.n_name AS nation, 
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM supplier_hierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY total_supply_cost DESC;
