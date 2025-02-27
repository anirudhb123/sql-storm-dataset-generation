SELECT 
    p.p_brand, 
    p.p_type, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(p.p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS supplier_details
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
    p.p_size BETWEEN 10 AND 20 
    AND r.r_name LIKE '%Europe%'
GROUP BY 
    p.p_brand, 
    p.p_type
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    avg_price DESC, 
    supplier_count DESC;
