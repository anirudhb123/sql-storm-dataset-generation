SELECT 
    s.s_name AS supplier_name,
    count(DISTINCT p.p_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_part_names,
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
    p.p_retailprice > 100 
    AND s.s_acctbal > 500
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_parts_supplied DESC, supplier_name;
