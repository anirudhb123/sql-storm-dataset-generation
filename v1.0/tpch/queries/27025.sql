SELECT 
    CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value,
    AVG(CASE 
            WHEN LENGTH(p.p_name) > 30 THEN LENGTH(p.p_name) 
            ELSE NULL 
        END) AS avg_long_part_name_length,
    STRING_AGG(DISTINCT p.p_type, ', ') AS unique_part_types
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Eu%')
GROUP BY 
    s.s_suppkey, s.s_name, n.n_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_inventory_value DESC;
