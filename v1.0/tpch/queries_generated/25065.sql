SELECT 
    p.p_name,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS short_comment,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type,
    (SELECT COUNT(*) 
     FROM partsupp ps 
     WHERE ps.ps_partkey = p.p_partkey) AS supplier_count,
    (SELECT SUM(ps.ps_supplycost) 
     FROM partsupp ps 
     WHERE ps.ps_partkey = p.p_partkey) AS total_supply_cost
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
    r.r_name = 'ASIA'
    AND LENGTH(p.p_name) > 10
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
