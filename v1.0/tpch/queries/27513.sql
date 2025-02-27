SELECT 
    p.p_partkey, 
    p.p_name, 
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS part_info,
    CASE 
        WHEN p.p_size < 10 THEN 'Small'
        WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
        ELSE 'Large'
    END AS size_category,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(s.s_name, ', ') AS suppliers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 50.00
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
