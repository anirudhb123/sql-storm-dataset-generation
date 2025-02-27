SELECT 
    s_name AS supplier_name,
    COUNT(DISTINCT ps_partkey) AS num_parts_supplied,
    SUM(ps_availqty) AS total_available_quantity,
    SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
    JSON_ARRAYAGG(DISTINCT CONCAT(p_name, ' (', p_type, ')')) AS supplied_parts
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s_comment LIKE '%urgent%'
GROUP BY 
    s_name
HAVING 
    total_supply_cost > 10000
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
