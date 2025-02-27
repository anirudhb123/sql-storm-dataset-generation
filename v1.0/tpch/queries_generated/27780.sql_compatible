
SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_mfgr, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    LEFT(p.p_comment, 10) AS short_comment,
    CONCAT('Type: ', p.p_type, ', Size: ', p.p_size) AS type_size
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100.00 
    AND p.p_mfgr LIKE 'Manufacturer%'
GROUP BY 
    p.p_name, 
    p.p_brand, 
    p.p_mfgr, 
    p.p_partkey, 
    p.p_comment, 
    p.p_type, 
    p.p_size
ORDER BY 
    total_avail_qty DESC, 
    avg_supply_cost ASC
LIMIT 50;
