SELECT 
    CONCAT('Part Name: ', p_name, ', Manufacturer: ', p_mfgr, ', Brand: ', p_brand) AS part_details,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', r.r_name, ')'), '; ') AS supplier_nation_region
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LENGTH(p.p_comment) > 10 AND 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
ORDER BY 
    num_suppliers DESC, avg_supply_cost ASC
LIMIT 100;
