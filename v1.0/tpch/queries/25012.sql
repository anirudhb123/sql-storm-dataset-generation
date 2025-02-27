SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(ps.ps_availqty) AS max_available_quantity,
    STRING_AGG(DISTINCT CONCAT('Part:', p.p_name, ' [', p.p_brand, ']'), '; ') AS parts_list
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_parts_supplied DESC;
