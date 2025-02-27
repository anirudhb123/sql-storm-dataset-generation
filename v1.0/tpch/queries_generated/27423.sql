SELECT 
    p.p_brand, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_supplycost) AS total_supply_cost,
    GROUP_CONCAT(DISTINCT CONCAT(s.s_name, ':', ps.ps_supplycost) ORDER BY ps.ps_supplycost DESC SEPARATOR '; ') AS supplier_details,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CASE 
        WHEN COUNT(DISTINCT s.s_suppkey) > 5 THEN 'Many Suppliers'
        ELSE 'Few Suppliers'
    END AS supplier_summary
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_brand
HAVING 
    total_supply_cost > 1000.00
ORDER BY 
    total_supply_cost DESC;
