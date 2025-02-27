SELECT 
    CONCAT('Supplier Name: ', s.s_name) AS supplier_info,
    CONCAT('Part Name: ', p.p_name, ', Retail Price: $', FORMAT(p.p_retailprice, 2)) AS part_info,
    CONCAT('Customer: ', c.c_name, ', Address: ', c.c_address) AS customer_info,
    CONCAT('Order Total: $', FORMAT(o.o_totalprice, 2), ', Order Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d')) AS order_info,
    GROUP_CONCAT(CONCAT('Line Item: ', l.l_orderkey, ', Quantity: ', l.l_quantity, ', Extended Price: $', FORMAT(l.l_extendedprice, 2)) SEPARATOR ' | ') AS line_items
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
    c.c_mktsegment = 'BUILDING'
    AND p.p_retailprice > 100.00
GROUP BY 
    s.s_suppkey, p.p_partkey, c.c_custkey, o.o_orderkey
ORDER BY 
    o.o_orderdate DESC, s.s_name ASC;
