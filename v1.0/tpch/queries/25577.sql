SELECT 
    s.s_name,
    s.s_address,
    CONCAT('Supplied ', COUNT(ps.ps_supplycost), ' parts: ', STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), '; ')) AS supplied_parts,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    CASE 
        WHEN SUM(ps.ps_supplycost) > 10000 THEN 'High Supply'
        WHEN SUM(ps.ps_supplycost) BETWEEN 5000 AND 10000 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END AS supply_level
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address
HAVING 
    COUNT(ps.ps_supplycost) > 2
ORDER BY 
    total_supply_cost DESC;
