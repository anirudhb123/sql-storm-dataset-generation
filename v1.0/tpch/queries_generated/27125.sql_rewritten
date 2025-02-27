SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1997-01-01'
GROUP BY 
    p.p_name, 
    s.s_name, 
    c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;