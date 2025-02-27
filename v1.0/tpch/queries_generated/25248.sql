SELECT 
    DISTINCT p.p_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(s.s_name, ' ', -1), ' ', 1) AS last_word_supplier,
    CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name) AS supplier_part_description,
    LENGTH(p.p_comment) AS comment_length,
    LEFT(p.p_comment, 10) AS short_comment,
    REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(p.p_name) > 10
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
ORDER BY 
    comment_length DESC, last_word_supplier ASC
LIMIT 100;
