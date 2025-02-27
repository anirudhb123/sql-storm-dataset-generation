SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
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
    p.p_name ILIKE '%widget%' 
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name
ORDER BY 
    total_revenue DESC
LIMIT 10;