SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT SUBSTRING(l.l_comment FROM 1 FOR 20), '; ') AS abbreviated_comments
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 10
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_discount > 0.05
GROUP BY 
    p.p_name, s.s_name, n.n_name
ORDER BY 
    total_quantity DESC, 
    avg_extended_price ASC;