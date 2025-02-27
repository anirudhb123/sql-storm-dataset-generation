SELECT 
    p.p_type,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_name LIKE '%rubber%'
GROUP BY 
    p.p_type, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    average_price DESC;
