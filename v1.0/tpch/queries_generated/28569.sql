SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Total Revenue: $', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS revenue_summary
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
    c.c_mktsegment = 'BUILDING'
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
