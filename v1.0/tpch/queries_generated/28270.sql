SELECT 
    p.p_name,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS short_comment,
    CONCAT(s.s_name, ' from ', c.c_name, ' in ', n.n_name) AS supplier_info,
    LEFT(s.s_address, 20) AS supplier_address,
    REPLACE(p.p_type, ' ', '_') AS formatted_type,
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = s.s_nationkey
JOIN 
    nation n ON n.n_nationkey = c.c_nationkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_name, short_comment, supplier_info, supplier_address, formatted_type
HAVING 
    average_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    total_orders DESC
LIMIT 10;
