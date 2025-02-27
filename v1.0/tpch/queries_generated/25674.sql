SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    CONCAT(p.p_name, ' (', p.p_mfgr, ')') AS part_description
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
    r.r_name LIKE 'Asia%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
