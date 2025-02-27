SELECT 
    p.p_name AS part_name, 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS ship_modes_used,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    AVG(ps.ps_supplycost) > 20.00
ORDER BY 
    total_orders DESC;
