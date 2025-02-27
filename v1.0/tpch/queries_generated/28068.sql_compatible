
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_totalprice) AS max_order_value,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ': ', s.s_name), '; ') AS customer_supplier_relationships,
    REPLACE(p.p_comment, 'GOOD', 'EXCELLENT') AS updated_comment
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    p.p_name,
    s.s_name,
    c.c_name,
    p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
