SELECT 
    n.n_name,
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01' AND 
    l.l_shipdate < DATE '1996-01-01'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    revenue DESC;
