SELECT 
    n.n_name AS nation, 
    r.r_name AS region, 
    SUM(o.o_totalprice) AS total_revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC;
