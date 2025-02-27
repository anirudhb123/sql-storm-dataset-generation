SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_name,
    p.p_size,
    s.s_address,
    s.s_phone,
    s.s_comment,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(o.o_totalprice) AS max_order_price,
    STRING_AGG(DISTINCT CASE 
                            WHEN c.c_mktsegment = 'BUILDING' THEN 'Building Customer'
                            WHEN c.c_mktsegment = 'FURNITURE' THEN 'Furniture Customer'
                            ELSE 'Other Customer' 
                        END, ', ') AS customer_segments
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_container LIKE '%BOX%'
GROUP BY 
    s.s_name, p.p_name, p.p_size, s.s_address, s.s_phone, s.s_comment
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;
