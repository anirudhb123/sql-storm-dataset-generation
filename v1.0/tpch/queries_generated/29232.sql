SELECT 
    p.p_partkey,
    p.p_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    REPLACE(p.p_mfgr, 'Manufacturer', 'Mfg') AS modified_mfgr,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type_info,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    avg_supply_cost DESC
LIMIT 100;
