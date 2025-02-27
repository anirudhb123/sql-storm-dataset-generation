SELECT 
    DISTINCT p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    (SELECT COUNT(*) 
     FROM orders o 
     JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
     WHERE l.l_quantity > 10 AND l.l_discount > 0.1) AS large_discount_orders,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00 
    AND s.s_acctbal > 1000.00 
    AND c.c_mktsegment = 'BUILDING'
ORDER BY 
    p.p_name, s.s_name;
