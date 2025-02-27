SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_description,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity_sold,
    AVG(l.l_extendedprice) AS avg_price_per_item
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
WHERE 
    s.s_name LIKE '%ABC%' AND 
    p.p_type = 'widget' AND 
    o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    total_quantity_sold > 100
ORDER BY 
    total_orders DESC, avg_price_per_item ASC;
