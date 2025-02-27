SELECT 
    p.p_name, 
    s.s_name, 
    r.r_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT c.c_comment, '; ') AS customer_comments
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    p.p_size >= 10 
    AND r.r_name LIKE 'Asia%' 
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31' 
GROUP BY 
    p.p_name, s.s_name, r.r_name 
HAVING 
    SUM(l.l_quantity) > 100 
ORDER BY 
    total_revenue DESC;