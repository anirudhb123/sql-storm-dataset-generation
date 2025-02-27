SELECT 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_size, ' ', p.p_container, ')'), ', ') AS part_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name LIKE 'A%' AND 
    p.p_type IN ('medicinal', 'industrial')
GROUP BY 
    s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    unique_parts_supplied DESC;
