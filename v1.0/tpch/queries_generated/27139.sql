SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS part_supplier_info,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS short_comment,
    REPLACE(p.p_comment, 'quality', 'excellence') AS updated_comment,
    LENGTH(p.p_comment) AS comment_length,
    CHAR_LENGTH(p.p_name) AS name_length,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_availability
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_partkey, s.s_suppkey
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_availability DESC;
