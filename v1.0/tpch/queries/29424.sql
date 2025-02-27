SELECT 
    CONCAT(r.r_name, ', ', n.n_name) AS location,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, '; ') AS products_offered,
    STRING_AGG(DISTINCT s.s_name, '; ') AS suppliers_for_region,
    AVG(l.l_discount) AS average_discount
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE 'N%' AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue DESC;