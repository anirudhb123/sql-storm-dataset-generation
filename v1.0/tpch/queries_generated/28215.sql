SELECT 
    CONCAT_WS(' - ', 
        CONCAT('Part: ', p_name), 
        CONCAT('Manufacturer: ', p_mfgr), 
        CONCAT('Brand: ', p_brand), 
        CONCAT('Type: ', p_type), 
        CONCAT('Size: ', p_size), 
        CONCAT('Container: ', p_container), 
        CONCAT('Retail Price: $', FORMAT(p_retailprice, 2)), 
        CONCAT('Comment: ', p_comment)
    ) AS part_details,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost
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
    r.r_name LIKE '%ASIA%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
ORDER BY 
    supplier_count DESC, avg_supply_cost ASC
LIMIT 10;
