SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_totalprice AS total_price,
    CONCAT('Order Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d'), 
           ', Part: ', p.p_name, 
           ', Supplier: ', s.s_name, 
           ', Customer: ', c.c_name) AS detailed_description
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    LENGTH(p.p_comment) > 5 
    AND (s.s_name LIKE 'A%' OR s.s_name LIKE 'B%' OR s.s_name LIKE 'C%')
ORDER BY 
    o.o_totalprice DESC;
