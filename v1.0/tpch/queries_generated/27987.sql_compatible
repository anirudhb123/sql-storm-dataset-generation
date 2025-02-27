
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT(s.s_name, ' (', r.r_name, ')') AS supplier_region,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT ps.ps_comment, '; ') AS unique_comments
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
WHERE 
    p.p_size > 10 AND o.o_orderdate >= DATE '1996-01-01'
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_orders DESC, total_revenue DESC;
