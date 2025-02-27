SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    n.n_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT l.l_comment, '; ') AS comments_aggregated
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
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31' 
    AND p.p_comment LIKE '%special%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, n.n_name, r.r_name 
ORDER BY 
    total_revenue DESC, total_orders DESC;