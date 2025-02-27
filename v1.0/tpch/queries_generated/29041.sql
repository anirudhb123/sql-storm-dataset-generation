SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.p_comment, ' ', 5), ' ', -5) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost
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
WHERE 
    s.s_name LIKE 'Supplier%'
    AND p.p_size BETWEEN 1 AND 50
    AND o.o_orderdate >= '2023-01-01'
GROUP BY 
    s.s_name, p.p_name, short_comment
HAVING 
    total_orders > 5
ORDER BY 
    average_supply_cost DESC, total_quantity DESC;
