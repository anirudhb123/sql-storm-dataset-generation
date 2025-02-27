SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    MAX(LENGTH(p.p_comment)) AS max_comment_length,
    STRING_AGG(DISTINCT SUBSTRING(p.p_comment, 1, 10), ', ') AS short_comments,
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
    p.p_size BETWEEN 1 AND 20
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_price DESC, supplier_count DESC;
