SELECT 
    p.p_name, 
    COUNT(*) AS total_orders, 
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), ', ', 5) AS top_suppliers,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS region_nation_info
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
    o.o_orderstatus = 'O'
    AND p.p_size > 20
    AND s.s_acctbal > 5000
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    total_orders > 10
ORDER BY 
    total_orders DESC, p.p_name ASC;
