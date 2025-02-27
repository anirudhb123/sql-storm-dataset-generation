SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderdate, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Ordered by: ', c.c_name) AS detailed_comment,
    LENGTH(p.p_comment) AS part_comment_length,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS part_comment_preview,
    REPLACE(p.p_container, 'box', 'package') AS updated_container
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
    p.p_size > 10
    AND c.c_mktsegment = 'BUILDING'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    o.o_orderdate DESC, 
    p.p_name ASC;
