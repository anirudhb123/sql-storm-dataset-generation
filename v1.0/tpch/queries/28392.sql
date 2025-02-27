SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS suppliers_details,
    CASE 
        WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
        WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(p.p_name) > 5 
    AND p.p_brand LIKE 'Brand%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_comment, p.p_size
ORDER BY 
    avg_supply_cost DESC;
