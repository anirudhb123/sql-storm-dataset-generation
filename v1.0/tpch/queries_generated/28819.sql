SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(CAST(CHAR_LENGTH(ps.ps_comment) AS INTEGER)) AS total_comment_length,
    AVG(p.p_retailprice) AS average_price,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(l.l_discount) AS min_discount,
    CONCAT('Supplier for ', p.p_name) AS comment_prefix
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    short_name 
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1 
ORDER BY 
    average_price DESC, 
    total_comment_length ASC;
