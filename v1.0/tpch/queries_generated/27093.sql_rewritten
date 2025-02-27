SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC;