SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    SUBSTRING_INDEX(s.s_comment, ' ', 5) AS comment_snippet,
    CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 5000
    AND p.p_type LIKE '%metal%'
GROUP BY 
    s.s_suppkey
HAVING 
    total_parts > 10
ORDER BY 
    total_cost DESC
LIMIT 10;
