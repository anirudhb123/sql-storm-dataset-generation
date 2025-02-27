SELECT 
    p.p_name,
    s.s_name,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_phone, ')'), '; ') AS customers_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
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
    p.p_name LIKE '%steel%'
    AND s.s_comment NOT LIKE '%import%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_quantity DESC, avg_extended_price DESC;