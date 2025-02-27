SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    MAX(o.o_totalprice) AS max_order_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE 'Rubber%'
AND 
    s.s_comment NOT LIKE '%no comment%'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, max_order_price ASC;
