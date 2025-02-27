SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', s.s_name, s.s_address), '; ') AS suppliers_info
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
