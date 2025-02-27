SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_info, 
    COUNT(o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments
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
    p.p_type LIKE '%brass%' AND 
    s.s_acctbal > 5000
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(o.o_orderkey) > 10 
ORDER BY 
    total_revenue DESC;
