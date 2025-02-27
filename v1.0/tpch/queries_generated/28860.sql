SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_revenue,
    STRING_AGG(DISTINCT r.r_name || ': ' || n.n_name, '; ') AS region_nation_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%'
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_available_quantity DESC, average_revenue DESC;
