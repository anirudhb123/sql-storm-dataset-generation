SELECT 
    p.p_name, 
    s.s_name, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    SUM(l.l_quantity) AS total_ordered_qty,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
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
    p.p_name LIKE '%rubber%' 
    AND s.s_comment NOT LIKE '%special%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_returned_qty DESC, total_ordered_qty ASC;