WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_supplycost > 100.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, ps.ps_partkey, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supplier_chain sc ON sc.s_suppkey = s.s_suppkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT sc.s_suppkey) AS supplier_count,
    SUM(sc.ps_supplycost) AS total_supply_cost,
    AVG(sc.ps_supplycost) AS average_supply_cost
FROM supplier_chain sc
JOIN nation n ON sc.s_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING SUM(sc.ps_supplycost) >= 10000.00
ORDER BY total_supply_cost DESC
LIMIT 10;
