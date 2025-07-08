
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    LISTAGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), ', ') WITHIN GROUP (ORDER BY s.s_name) AS suppliers_info,
    SUBSTR(p.p_comment, 1, 15) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    avg_supply_cost DESC
LIMIT 10;
