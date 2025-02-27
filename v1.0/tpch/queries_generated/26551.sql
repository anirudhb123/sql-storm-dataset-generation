SELECT 
    SUM(CASE 
        WHEN LENGTH(p_name) > 10 THEN 1 
        ELSE 0 
    END) AS long_part_names,
    COUNT(DISTINCT s.s_name) AS unique_suppliers,
    AVG(CASE 
        WHEN p_retailprice > 100 THEN p_retailprice 
        ELSE NULL 
    END) AS avg_high_price_parts,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_involved
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_container LIKE 'BOX%' 
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_size
ORDER BY 
    long_part_names DESC, 
    avg_high_price_parts DESC;
