SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name FROM 1 FOR 10) AS short_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS details,
    CASE 
        WHEN p.p_retailprice > 50 THEN 'Expensive'
        WHEN p.p_retailprice BETWEEN 20 AND 50 THEN 'Moderate'
        ELSE 'Cheap'
    END AS price_category,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_comment LIKE '%quality%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice
ORDER BY 
    p.p_partkey;
