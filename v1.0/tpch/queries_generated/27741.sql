SELECT 
    SUBSTRING(p.p_name, 1, 15) AS truncated_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(p.p_retailprice) AS average_price,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
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
    p.p_comment LIKE '%special%' 
GROUP BY 
    p.p_name, r.r_name
HAVING 
    AVG(p.p_retailprice) > 100
ORDER BY 
    average_price DESC;
