SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Price: $', FORMAT(ps.ps_supplycost, 2)) AS detailed_info,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length,
    REPLACE(s.s_comment, 'good', 'excellent') AS modified_supplier_comment
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_size > 20 AND s.s_acctbal > 5000
ORDER BY 
    comment_length DESC, 
    s.s_name ASC
LIMIT 50;
