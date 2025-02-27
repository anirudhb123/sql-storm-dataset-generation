SELECT 
    CONCAT('Supplier: ', s_name, ' | Address: ', s_address, ' | Nation: ', n_name) AS supplier_info,
    COUNT(DISTINCT ps_partkey) AS unique_parts_supplied,
    SUM(ps_availqty) AS total_available_quantity,
    SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
    GROUP_CONCAT(DISTINCT p_name ORDER BY p_name SEPARATOR ', ') AS supplied_parts
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
GROUP BY 
    s.s_suppkey
HAVING 
    SUM(ps_availqty) > 100
ORDER BY 
    total_supply_cost DESC;
