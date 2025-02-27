SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    STRING_AGG(l.l_comment, '; ') AS line_comments
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
    p.p_size BETWEEN 10 AND 20 
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderstatus IN ('O', 'F')
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
ORDER BY 
    o.o_totalprice DESC, c.c_name ASC;