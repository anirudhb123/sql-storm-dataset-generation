
SELECT
    s.s_name,
    COUNT(DISTINCT ps.ps_partkey) AS distinct_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost,
    LISTAGG(DISTINCT p.p_type, ', ') WITHIN GROUP (ORDER BY p.p_type) AS part_types,
    LISTAGG(DISTINCT CONCAT(p.p_mfgr, ' - ', p.p_brand), ', ') WITHIN GROUP (ORDER BY p.p_mfgr, p.p_brand) AS mfgr_brand_pairs
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE n.n_name LIKE 'A%' 
AND p.p_size >= 10
AND p.p_retailprice BETWEEN 50.00 AND 150.00
GROUP BY s.s_name
HAVING COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY total_available_quantity DESC, s.s_name;
