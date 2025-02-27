SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extendedprice,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS total_returns,
    STRING_AGG(DISTINCT CONCAT_WS(', ', l.l_shipmode, l.l_comment), '; ') AS ship_modes_comments
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
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC
LIMIT 50;
