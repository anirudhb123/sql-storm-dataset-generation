SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers,
    SUM(CASE 
        WHEN LENGTH(p.p_comment) > 0 THEN LENGTH(p.p_comment) 
        ELSE 0 
    END) AS total_comment_length,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    AVG(s.s_acctbal) AS average_supplier_balance,
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_comment,
    CONCAT('Part Name: ', p.p_name, ' | Size: ', p.p_size) AS part_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_size, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_comment_length DESC
LIMIT 50;
