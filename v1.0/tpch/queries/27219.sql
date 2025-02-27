
SELECT 
    CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts,
    r.r_name AS region_name
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size = (SELECT MAX(p_size) FROM part)
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    s.s_suppkey, s.s_name, n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_available_quantity DESC, supplier_info;
