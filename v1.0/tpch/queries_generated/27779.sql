SELECT 
    p.p_partkey,
    INITCAP(p.p_name) AS formatted_name,
    CONCAT('Manufacturer: ', p.p_mfgr) AS mfgr_info,
    REPLACE(p.p_comment, 'poor', 'excellent') AS updated_comment,
    SUBSTRING_INDEX(p.p_type, ' ', 1) AS primary_type,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_availqty) AS min_avail_qty,
    GROUP_CONCAT(DISTINCT s.s_name SEPARATOR ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND p.p_retailprice > 30.00
GROUP BY 
    p.p_partkey, 
    formatted_name,
    mfgr_info,
    updated_comment,
    primary_type
HAVING 
    supplier_count > 1
ORDER BY 
    max_supply_cost DESC;
