SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_comment), '; ') AS supplier_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 
    (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    avg_retail_price DESC;
