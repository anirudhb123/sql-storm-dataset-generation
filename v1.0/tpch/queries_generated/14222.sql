SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING'
    AND l.l_shipdate >= DATE '2022-01-01'
    AND l.l_shipdate < DATE '2022-12-31'
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
