SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    s.s_address,
    c.c_name,
    o.o_orderkey,
    o.o_totalprice,
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(CONCAT(l.l_comment, ' | Order Date: ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD')), '; ') AS detailed_comments
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
    LENGTH(p.p_name) > 10
    AND s.s_acctbal > 10000
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_address, c.c_name, o.o_orderkey, o.o_totalprice
ORDER BY 
    total_quantity DESC, o.o_totalprice DESC;
