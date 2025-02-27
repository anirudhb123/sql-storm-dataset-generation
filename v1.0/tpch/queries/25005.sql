SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    MAX(LENGTH(p.p_comment)) AS max_comment_length,
    MIN(LENGTH(p.p_comment)) AS min_comment_length,
    r.r_name AS region_name
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
    LENGTH(p.p_name) > 10
    AND p.p_retailprice > 20.00
GROUP BY 
    p.p_name, r.r_name
HAVING 
    AVG(p.p_retailprice) > 50.00
ORDER BY 
    MAX(LENGTH(p.p_comment)) DESC, supplier_count DESC;
