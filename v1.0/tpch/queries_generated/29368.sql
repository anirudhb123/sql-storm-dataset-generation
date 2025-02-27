SELECT 
    p.p_name, 
    STRING_AGG(CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    AVG(l.l_extendedprice) AS avg_extended_price
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
    p.p_size > 10 AND 
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_returned DESC, 
    avg_extended_price DESC;
