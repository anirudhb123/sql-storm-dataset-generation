SELECT 
    CONCAT(s.s_name, ' (', r.r_name, ')') AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    SUM(ps.ps_availqty) AS total_quantity_available,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_quantity_available DESC
LIMIT 10;
