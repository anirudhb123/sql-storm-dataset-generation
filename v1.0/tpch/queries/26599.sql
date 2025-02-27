SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', s.s_address, s.s_phone), '; ') AS supplier_details
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
    p.p_name LIKE '%Widget%' 
    AND o.o_orderdate >= DATE '1997-01-01' 
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;