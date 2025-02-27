SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    n.n_name AS supplier_nation,
    CASE 
        WHEN char_length(p.p_comment) > 20 THEN substr(p.p_comment, 1, 20) || '...'
        ELSE p.p_comment 
    END AS truncated_comment,
    regexp_replace(n.r_name, '([a-z]+)([A-Z])', '\1 \2', 'g') AS formatted_region_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity
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
    p.p_brand LIKE 'Brand#%'
    AND p.p_size IN (10, 20, 30)
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name, p.p_comment, n.r_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC;
