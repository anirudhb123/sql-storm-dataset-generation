
SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS info,
    REPLACE(p.p_comment, 'discount', 'reduced price') AS modified_comment,
    TRIM(LEADING '0' FROM CAST(ps.ps_supplycost AS STRING)) AS cost_no_leading_zero,
    SUBSTR(s.s_address, 1, 20) AS short_address,
    LENGTH(s.s_comment) AS comment_length
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    (s.s_comment LIKE '%important%' OR p.p_comment LIKE '%important%')
AND 
    s.s_acctbal BETWEEN 1000.00 AND 5000.00
GROUP BY 
    s.s_name, p.p_name, p.p_comment, ps.ps_supplycost, s.s_address, s.s_comment
ORDER BY 
    LENGTH(p.p_name) DESC, s.s_name ASC
LIMIT 50;
