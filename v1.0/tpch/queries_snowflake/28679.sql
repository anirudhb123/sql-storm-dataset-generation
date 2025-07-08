
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names,
    REPLACE(UPPER(p.p_comment), 'FOO', 'BAR') AS modified_comment,
    CONCAT('Part Name: ', p.p_name, ', Total Quantity: ', SUM(l.l_quantity)) AS report,
    LENGTH(p.p_comment) AS comment_length,
    LENGTH(s.s_name) AS supplier_name_length
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_name, p.p_comment, p.p_retailprice
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    total_quantity DESC, average_retail_price ASC;
