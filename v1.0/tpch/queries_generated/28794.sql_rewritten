SELECT 
    CONCAT(s.s_name, ' (', p.p_name, ')') AS supplier_part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_served
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_type LIKE '%widget%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_quantity DESC, total_orders DESC
LIMIT 10;