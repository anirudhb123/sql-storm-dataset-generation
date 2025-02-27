SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT(s.s_address, ', ', n.n_name) AS supplier_location, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    COUNT(o.o_orderkey) AS total_orders, 
    AVG(o.o_totalprice) AS average_order_value, 
    SUBSTRING(p.p_comment, 1, 15) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE 'green%' 
    AND s.s_comment NOT LIKE '%defective%' 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, average_order_value DESC;
