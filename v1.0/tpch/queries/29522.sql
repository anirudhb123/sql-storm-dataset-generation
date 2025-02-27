SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    AVG(o.o_totalprice) AS average_order_value,
    string_agg(DISTINCT c.c_name, ', ') AS customers
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
WHERE 
    s.s_comment LIKE '%special%' 
    AND p.p_type IN ('Fasteners', 'Widgets')
    AND l.l_returnflag = 'N'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_available_quantity DESC, 
    average_order_value DESC
LIMIT 20;
