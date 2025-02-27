SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', c.c_address, ')'), '; ') AS customer_details
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
WHERE 
    s.s_acctbal > 100
    AND p.p_retailprice < 50
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_available_quantity DESC;
