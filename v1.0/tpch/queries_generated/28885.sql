SELECT 
    CONCAT('Supplier: ', s_name, ', from: ', s_address, ', Nation: ', n_name) AS supplier_info,
    COUNT(DISTINCT ps_partkey) AS num_parts_supplied,
    SUM(ps_availqty) AS total_available_quantity,
    GROUP_CONCAT(DISTINCT p_name ORDER BY p_name SEPARATOR ', ') AS part_names,
    SUM(l_quantity) AS total_quantity_ordered,
    AVG(o_totalprice) AS avg_order_value
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.r_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
GROUP BY 
    supplier_info
HAVING 
    total_available_quantity > 100
ORDER BY 
    avg_order_value DESC;
