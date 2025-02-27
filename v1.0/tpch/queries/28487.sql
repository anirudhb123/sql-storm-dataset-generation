SELECT 
    p.p_name AS part_name, 
    CONCAT_WS(' ', s.s_name, 'supplies', p.p_size, 'units of', p.p_type) AS supply_statement, 
    (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supplier_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%deluxe%' AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, p.p_size, p.p_type
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    supplier_count DESC, order_count DESC;