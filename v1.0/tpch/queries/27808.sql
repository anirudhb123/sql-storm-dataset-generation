SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(CONCAT(s.s_name, ':', s.s_address), '; ') AS supplier_details
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
    p.p_size > 25
AND 
    l.l_discount > 0.05
AND 
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_quantity DESC, unique_customers DESC
LIMIT 10;