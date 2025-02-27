SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name FROM 1 FOR 20) AS short_name,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type,
    REPLACE(p.p_comment, 'excellent', 'superb') AS updated_comment,
    COUNT(s.s_suppkey) AS supplier_count,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment
HAVING 
    COUNT(s.s_suppkey) > 3
ORDER BY 
    p.p_partkey ASC;
