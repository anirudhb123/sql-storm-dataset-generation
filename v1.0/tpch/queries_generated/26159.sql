SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(p_retailprice) AS avg_retail_price,
    MAX(LENGTH(p_comment)) AS max_comment_length,
    GROUP_CONCAT(DISTINCT r_name ORDER BY r_name SEPARATOR ', ') AS regions
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
    p_size > 20
AND 
    p_comment LIKE '%quality%'
GROUP BY 
    short_name
HAVING 
    supplier_count > 5
ORDER BY 
    avg_retail_price DESC
LIMIT 10;
