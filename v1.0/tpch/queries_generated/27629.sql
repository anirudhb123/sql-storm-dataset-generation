SELECT 
    CONCAT('Supplier: ', s_name, ' | Address: ', s_address, ' | Phone: ', s_phone) AS supplier_info,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts_supplied,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    r.r_name AS region_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'E%'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, s.s_phone, r.r_name
HAVING 
    SUM(ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
