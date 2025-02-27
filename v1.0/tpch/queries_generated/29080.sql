SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), ',', 5) AS top_suppliers,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '2023-01-01' 
    AND o.o_orderdate < '2024-01-01' 
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    total_orders > 10
ORDER BY 
    total_revenue DESC
LIMIT 20;
