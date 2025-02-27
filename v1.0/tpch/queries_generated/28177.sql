SELECT 
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(CASE WHEN p.p_size IS NOT NULL THEN p.p_size ELSE 0 END) AS max_part_size,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'EUROPE%'
    AND s.s_comment NOT LIKE '%discount%'
GROUP BY 
    s.s_name, s.s_address
HAVING 
    AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    total_parts_supplied DESC;
