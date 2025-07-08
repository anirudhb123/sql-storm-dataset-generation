
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS part_details,
    LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'Europe'
    AND p.p_container IS NOT NULL
    AND LENGTH(p.p_name) > 10
GROUP BY 
    p.p_name, p.p_mfgr, p.p_type
ORDER BY 
    total_available_quantity DESC, 
    average_supply_cost ASC
LIMIT 
    10;
