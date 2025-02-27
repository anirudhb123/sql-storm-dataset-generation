SELECT 
    p.p_name, 
    p.p_mfgr, 
    p.p_type, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count, 
    SUM(CASE 
            WHEN LENGTH(ps.ps_comment) > 50 THEN 1 
            ELSE 0 
        END) AS long_comment_count,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), ', ', 5) AS top_suppliers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_brand LIKE 'Brand%'
    AND p.p_container IN ('BOX', 'PACKAGE')
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_type
HAVING 
    supplier_count > 2
ORDER BY 
    long_comment_count DESC, supplier_count DESC
LIMIT 10;
