SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS number_of_parts,
    STRING_AGG(DISTINCT CONCAT('(', p.p_partkey, ') ', p.p_name), '; ') AS part_details,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
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
    p.p_retailprice > 100.00
    AND s.s_acctbal > 1000.00
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_supply_cost DESC;
