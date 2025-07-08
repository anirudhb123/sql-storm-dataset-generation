SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    CONCAT(CAST(o.o_orderkey AS CHAR), '-', p.p_partkey, '-', s.s_suppkey) AS unique_identifier,
    TRIM(CONCAT(p.p_comment, ' ', s.s_comment)) AS combined_comments,
    LENGTH(TRIM(CONCAT(p.p_comment, ' ', s.s_comment))) AS comments_length,
    CASE 
        WHEN LENGTH(TRIM(CONCAT(p.p_comment, ' ', s.s_comment))) > 100 THEN 'LONG'
        ELSE 'SHORT'
    END AS comment_length_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%steel%'
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
ORDER BY 
    comments_length DESC
LIMIT 100;
