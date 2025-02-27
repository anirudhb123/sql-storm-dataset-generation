SELECT 
    LOWER(SUBSTRING(p_name, 1, 10)) AS short_name,
    COUNT(DISTINCT s_nationkey) AS unique_nations,
    SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
    CONCAT('Supplier: ', s_name, ' | Part: ', p_name) AS supplier_part_info,
    REPLACE(p_comment, 'obsolete', 'current') AS updated_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    short_name, s_name
HAVING 
    total_supply_cost > 10000
ORDER BY 
    unique_nations DESC, short_name ASC;
