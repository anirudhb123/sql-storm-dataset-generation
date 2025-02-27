SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_price,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ': ', o.o_orderdate, ' - ', l.l_comment), '; ') AS order_details
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND p.p_type LIKE '%BRASS%'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_quantity DESC, average_price DESC;