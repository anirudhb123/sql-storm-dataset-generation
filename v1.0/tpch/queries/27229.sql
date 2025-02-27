SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments,
    MAX(o.o_totalprice) AS max_order_price,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS avg_discount
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
    p.p_type LIKE '%brass%'
    AND o.o_orderdate >= '1996-01-01'
    AND o.o_orderdate < '1996-12-31'
GROUP BY 
    p.p_name, supplier_info
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, max_order_price DESC;