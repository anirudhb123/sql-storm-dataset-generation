SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    CONCAT('The supplier ', s.s_name, ' supplies the part ', p.p_name, ' to customer ', c.c_name, '.') AS description,
    LENGTH(p.p_comment) AS comment_length,
    UPPER(s.s_comment) AS supplier_comment_uppercase,
    REGEXP_REPLACE(c.c_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_customer_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 5000.00
    AND o.o_orderstatus IN ('O', 'F')
ORDER BY 
    comment_length DESC, p.p_name;
