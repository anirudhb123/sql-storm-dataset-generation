SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    COUNT(l.l_linenumber) AS total_lines,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    MAX(o.o_orderdate) AS last_order_date
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
    p.p_name LIKE '%metal%'
    AND o.o_orderstatus = 'O'
    AND l.l_discount BETWEEN 0.05 AND 0.20
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, total_lines DESC;
