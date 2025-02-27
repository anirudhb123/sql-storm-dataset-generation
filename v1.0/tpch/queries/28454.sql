
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT('OrderID: ', o.o_orderkey, ' (', o.o_orderdate, ')'), '; ') AS order_details,
    AVG(l.l_extendedprice) AS average_price,
    MAX(CASE WHEN l.l_shipdate < DATE '1998-10-01' THEN 'Shipped' ELSE 'Pending' END) AS shipping_status
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%reliable%'
    AND p.p_type = 'widget'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_orders DESC, average_price DESC;
