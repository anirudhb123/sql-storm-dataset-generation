SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    UPPER(CONCAT('Manufacturer: ', p_mfgr)) AS mfgr_info,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    AVG(p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT r_name, ', ') AS regions_supplied
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
    p_size > 10 AND 
    p_comment LIKE '%fragile%'
GROUP BY 
    SUBSTRING(p_name, 1, 10), UPPER(CONCAT('Manufacturer: ', p_mfgr))
HAVING 
    AVG(p_retailprice) > 50.00
ORDER BY 
    avg_price DESC
LIMIT 10;
