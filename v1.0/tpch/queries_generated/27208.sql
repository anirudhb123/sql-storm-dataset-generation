SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name, ', Customer: ', c.c_name) AS summary,
    LENGTH(p.p_comment) AS comment_length,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS first_five_words,
    COALESCE(NULLIF(CHAR_LENGTH(p.p_comment) - CHAR_LENGTH(REPLACE(p.p_comment, ' ', '')), 0), 1) AS word_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    uCASE(SUBSTRING(p.p_comment, 1, 3)) = 'NOW'
ORDER BY 
    comment_length DESC, summary
LIMIT 100;
