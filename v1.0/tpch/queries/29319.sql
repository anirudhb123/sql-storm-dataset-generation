
SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_quantity) AS total_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    AVG(l.l_extendedprice) AS avg_price
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
    p.p_name LIKE '%widget%' 
    AND s.s_name NOT LIKE '%cheap%' 
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    AVG(l.l_extendedprice) DESC;
