SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Cost: $', FORMAT(ps_supplycost, 2)) AS detailed_info,
    SUBSTRING(p_comment, 1, 20) AS brief_comment,
    REPLACE(s_comment, 'satisfied', 'Satisfied') AS adjusted_comment,
    CHAR_LENGTH(p_name) AS name_length,
    REGEXP_REPLACE(s_address, '[0-9]', '') AS sanitized_address
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p_size BETWEEN 10 AND 20
AND 
    s_acctbal > 1000
ORDER BY 
    detailed_info DESC
LIMIT 50;
