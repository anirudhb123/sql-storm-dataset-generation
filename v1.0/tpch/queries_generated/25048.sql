SELECT 
    SUBSTRING(p_name, 1, 20) AS short_name,
    CONCAT('Manufactured by ', p_mfgr) AS mfgr_description,
    REPLACE(p_comment, 'nice', 'pleasant') AS updated_comment,
    CASE 
        WHEN p_size > 10 THEN 'Large'
        WHEN p_size BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Small' 
    END AS size_category,
    COUNT(DISTINCT ps_suppkey) AS supplier_count,
    MAX(ps_supplycost) AS max_supply_cost,
    MIN(ps_supplycost) AS min_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    short_name, mfgr_description, updated_comment, size_category
HAVING 
    supplier_count > 1
ORDER BY 
    size_category DESC, max_supply_cost DESC;
