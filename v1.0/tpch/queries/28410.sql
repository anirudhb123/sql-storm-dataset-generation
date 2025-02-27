SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(CASE 
            WHEN LENGTH(p.p_name) > 30 THEN 1 
            ELSE 0 
        END) AS long_part_names,
    AVG(CASE 
            WHEN LENGTH(p.p_comment) > 50 THEN p.p_retailprice 
            ELSE NULL 
        END) AS avg_price_for_long_comments,
    COUNT(DISTINCT s.s_name) AS unique_suppliers,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' - ', p.p_name), '; ') AS supplier_part_relationships
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
    p.p_type LIKE '%brass%'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    nation_name, region_name;
