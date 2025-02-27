SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part_info, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
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
    LENGTH(p.p_name) > 10
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, supplier_part_info ASC;
