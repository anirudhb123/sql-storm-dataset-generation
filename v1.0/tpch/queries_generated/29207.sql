SELECT 
    p.p_brand, 
    p.p_type, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(CASE WHEN LENGTH(ps.ps_comment) > 50 THEN 1 ELSE 0 END) AS long_comments,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' - ', s.s_phone), '; ') AS supplier_details
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
    r.r_name LIKE 'Europe%' 
    AND p.p_size > 20
GROUP BY 
    p.p_brand, 
    p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_retail_price DESC;
