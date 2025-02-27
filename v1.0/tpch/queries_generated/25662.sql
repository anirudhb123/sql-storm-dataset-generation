SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr) AS full_mfgr_info,
    REPLACE(p.p_comment, 'obsolete', 'updated') AS updated_comment,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 50.00)
GROUP BY 
    short_name, full_mfgr_info, updated_comment
HAVING 
    total_supply_value > 1000.00
ORDER BY 
    total_supply_value DESC;
