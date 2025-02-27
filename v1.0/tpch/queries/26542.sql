SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier ', s.s_name, ' provides part ', p.p_name) AS full_description,
    COUNT(ps.ps_availqty) AS available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customers_served
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
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    AVG(ps.ps_supplycost) > 50.00
ORDER BY 
    available_quantity DESC, average_supply_cost ASC;