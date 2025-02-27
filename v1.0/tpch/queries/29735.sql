SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')'), '; ') AS customer_details
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
LEFT JOIN 
    customer c ON c.c_custkey = o.o_custkey 
WHERE 
    p.p_name LIKE '%widget%' 
    AND s.s_comment NOT LIKE '%special%'
GROUP BY 
    s.s_name, p.p_name 
HAVING 
    SUM(ps.ps_availqty) > 100 
ORDER BY 
    total_supply_cost DESC, 
    total_available_quantity ASC;
