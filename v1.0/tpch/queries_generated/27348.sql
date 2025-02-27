SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, '(', s.s_phone, ')'), ', ') AS supplier_details,
    CASE 
        WHEN AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp) THEN 'Above Average'
        ELSE 'Below Average' 
    END AS cost_comparison
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_brand LIKE '%BrandA%'
    AND p.p_type IN ('Type1', 'Type2', 'Type3')
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
