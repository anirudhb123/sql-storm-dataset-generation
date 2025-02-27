SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice - l.l_discount) AS avg_price_after_discount,
    STRING_AGG(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END, ', ') AS return_status
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
    p.p_type LIKE '%metal%'
    AND o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, avg_price_after_discount;