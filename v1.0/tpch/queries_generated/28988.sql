SELECT 
    s.s_name AS supplier_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(o.o_totalprice) AS average_order_value,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', p.p_name, p.p_comment), ', ') AS parts_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    s.s_comment LIKE '%limited%'
GROUP BY 
    s.s_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
