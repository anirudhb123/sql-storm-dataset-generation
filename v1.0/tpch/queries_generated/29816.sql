SELECT 
    p.p_name, 
    CONCAT(p.p_name, ' - ', p.p_comment) AS full_description, 
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS short_comment, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MIN(ps.ps_availqty) AS min_available_quantity,
    MAX(ps.ps_supplycost) AS max_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%brass%'
GROUP BY 
    p.p_partkey, full_description
HAVING 
    supplier_count > 2 
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;
