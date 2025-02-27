WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment, 1 AS level
    FROM part
    WHERE p_size >= 10

    UNION ALL

    SELECT p.partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice * 0.9, p.p_comment, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_size < 10 AND ph.level < 5
),
total_cost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_revenue > 10000
    ORDER BY total_revenue DESC
    LIMIT 5
)
SELECT ph.p_name, ph.p_mfgr, ph.p_brand, ph.p_retailprice, COALESCE(tc.total_supply_cost, 0) AS total_supply_cost, 
       ts.total_revenue AS top_supplier_revenue
FROM part_hierarchy ph
LEFT JOIN total_cost tc ON ph.p_partkey = tc.ps_partkey
LEFT JOIN top_suppliers ts ON ph.p_partkey = ts.s_suppkey
WHERE ph.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
  AND (ph.p_type LIKE 'TYPE%' OR ph.p_container IS NULL)
ORDER BY ph.level, ph.p_name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
