SELECT 
    CONCAT(s.s_name, ' ', c.c_name) AS supplier_customer, 
    p.p_name AS part_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice) AS total_revenue, 
    AVG(p.p_retailprice) AS average_part_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS region_names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    p.p_comment LIKE '%fragile%'
GROUP BY 
    supplier_customer, part_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
