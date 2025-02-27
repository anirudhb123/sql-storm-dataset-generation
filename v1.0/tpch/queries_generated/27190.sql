SELECT 
    s_name,
    COUNT(DISTINCT ps_partkey) AS unique_parts,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(ps_supplycost) AS average_supply_cost,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT p_type ORDER BY p_type ASC SEPARATOR ', '), ', ', 1) AS first_type,
    LEFT(SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT p_name ORDER BY p_name ASC SEPARATOR ', '), ', ', 1), 40) AS first_part_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
WHERE 
    c.c_mktsegment = 'FURNITURE'
GROUP BY 
    s_name
HAVING 
    unique_parts > 5
ORDER BY 
    total_available_quantity DESC;
