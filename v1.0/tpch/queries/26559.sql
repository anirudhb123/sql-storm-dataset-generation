SELECT 
    CONCAT('Supplier: ', s.s_name, ' (', s.s_suppkey, ')') AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT('Part: ', p.p_name, ' [', p.p_partkey, '] - Price: $', p.p_retailprice), ', ') AS parts_details,
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
    r.r_name LIKE '%East%' 
GROUP BY 
    s.s_suppkey, s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_available_quantity DESC;
