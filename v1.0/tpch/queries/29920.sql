SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
    r.r_name AS region_name
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
    p.p_size > 10 AND 
    s.s_acctbal > 5000 
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_supply_value DESC;
