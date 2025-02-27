SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost_value,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date,
    SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name SEPARATOR ', '), ', ', 3), ', ', -3) AS top_suppliers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%special%' AND
    s.s_comment NOT LIKE '%damaged%'
GROUP BY 
    p.p_partkey
HAVING 
    total_available_quantity > 100
ORDER BY 
    total_cost_value DESC;
