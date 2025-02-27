SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Location: ', s.s_address, ' | Phone: ', s.s_phone) AS Supplier_Info,
    CONCAT('Part: ', p.p_name, ' | Type: ', p.p_type, ' | Price: $', FORMAT(p.p_retailprice, 2)) AS Part_Info,
    CONCAT('Customer: ', c.c_name, ' | Market Segment: ', c.c_mktsegment) AS Customer_Info,
    CONCAT('Order Total: $', FORMAT(o.o_totalprice, 2), ' | Status: ', o.o_orderstatus, ' | Priority: ', o.o_orderpriority) AS Order_Info
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
    s.s_comment LIKE '%quality%' 
    AND c.c_mktsegment = 'BUILDING' 
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    o.o_orderdate DESC, 
    s.s_name ASC;
