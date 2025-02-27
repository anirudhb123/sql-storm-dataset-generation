SELECT 
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info,
    COUNT(*) AS total_parts,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT p.p_name ORDER BY p.p_name) AS part_names,
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
    p.p_size BETWEEN 10 AND 100
    AND p.p_comment LIKE '%quality%'
GROUP BY 
    s.s_name, s.s_nationkey, r.r_name
HAVING 
    AVG(p.p_retailprice) > 50
ORDER BY 
    total_parts DESC;
