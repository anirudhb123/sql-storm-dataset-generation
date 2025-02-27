SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_type, ')'), '; ') AS part_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_supply_cost DESC;
