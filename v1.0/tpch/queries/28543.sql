SELECT 
    p.p_name,
    s.s_name,
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS aggregated_comments
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
    p.p_size BETWEEN 10 AND 20
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
HAVING 
    SUM(l.l_discount) > 0.1
ORDER BY 
    total_revenue DESC
LIMIT 50;