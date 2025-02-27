SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate >= DATE '2022-01-01' 
    AND o.o_orderdate < DATE '2023-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    revenue DESC
LIMIT 100;
