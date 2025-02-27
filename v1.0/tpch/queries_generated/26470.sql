SELECT 
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_region,
    COUNT(DISTINCT ps.ps_partkey) AS available_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.r_name LIKE 'A%'
    AND p.p_brand NOT LIKE '%generic%'
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 10
ORDER BY 
    total_available_quantity DESC;
