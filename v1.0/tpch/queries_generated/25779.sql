SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    AVG(o.o_totalprice) AS avg_order_value, 
    CONCAT('Total Revenue: $', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS formatted_revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name IN (SELECT DISTINCT r_name FROM region r WHERE r.r_comment LIKE '%high demand%')
GROUP BY 
    p.p_name
HAVING 
    revenue > 10000
ORDER BY 
    revenue DESC;
