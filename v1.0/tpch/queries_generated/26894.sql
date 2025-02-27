SELECT 
    s_name AS supplier_name,
    COUNT(DISTINCT p_partkey) AS distinct_parts_supplied,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(ps_supplycost) AS average_supply_cost,
    MAX(p_retailprice) AS max_part_price,
    STRING_AGG(DISTINCT p_type, ', ') AS part_types_supplied,
    r_name AS region_name
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
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
GROUP BY 
    s.s_suppkey, s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_available_quantity DESC, supplier_name ASC;
