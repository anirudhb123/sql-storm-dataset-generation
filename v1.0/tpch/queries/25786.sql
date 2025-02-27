
SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE 
            WHEN LENGTH(p.p_comment) > 0 THEN 1 
            ELSE 0 
        END) AS non_empty_comments,
    AVG(CHAR_LENGTH(s.s_name)) AS avg_supplier_name_length,
    STRING_AGG(CONCAT(s.s_name, ' - ', s.s_comment), '; ') AS suppliers_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10 
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name
ORDER BY 
    supplier_count DESC, 
    non_empty_comments DESC
LIMIT 10;
