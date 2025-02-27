SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT('Supplier ', s.s_name, ' provides ', p.p_name) AS supplier_part_description,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' - ', r.r_name), '; ') AS countries_and_regions
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
    p.p_comment LIKE '%quality%'
GROUP BY 
    p.p_partkey, p.p_name, s.s_suppkey, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_orders DESC, average_discount DESC;
