SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    REPLACE(p.p_brand, 'Brand A', 'Brand X') AS modified_brand,
    CONCAT('Part: ', p.p_name, ' | Comment: ', SUBSTRING(p.p_comment, 1, 20)) AS detailed_info,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS suppliers_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    average_supply_cost DESC
LIMIT 10;
