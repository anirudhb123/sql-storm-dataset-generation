SELECT 
    p.p_name, 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS location_info,
    CASE 
        WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
        WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
        WHEN p.p_size > 20 THEN 'Large'
    END AS size_category
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
    p.p_comment LIKE '%fragile%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.r_name, n.n_name, p.p_size
HAVING 
    AVG(ps.ps_supplycost) > 100
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC;
