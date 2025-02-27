
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_served,
    CONCAT('Supplier (', s.s_name, ') from ', SUBSTRING(s.s_address, 1, 20), '...') AS supplier_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    s.s_name, p.p_name, s.s_address
HAVING 
    SUM(ps.ps_availqty) > 100 AND AVG(l.l_discount) < 0.1
ORDER BY 
    total_available_quantity DESC, total_orders DESC;
