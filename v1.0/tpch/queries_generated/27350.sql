SELECT 
    SUBSTRING(p.p_name, 1, 10) AS truncated_part_name,
    LENGTH(p.p_name) AS name_length,
    CONCAT('Part ', p.p_name) AS concatenated_part_name,
    REPLACE(p.p_comment, 'bad', 'good') AS sanitized_comment,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers_count,
    MAX(s.s_acctbal) AS max_supplier_balance,
    MIN(s.s_acctbal) AS min_supplier_balance,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    truncated_part_name, name_length, concatenated_part_name, sanitized_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    name_length DESC;
