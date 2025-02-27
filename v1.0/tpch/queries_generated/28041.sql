SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
        WHEN LENGTH(p.p_comment) > 10 THEN LENGTH(p.p_comment) 
        ELSE NULL 
    END) AS avg_length_comment,
    STRING_AGG(p.p_comment, '; ') WITHIN GROUP (ORDER BY p.p_partkey) AS aggregated_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
