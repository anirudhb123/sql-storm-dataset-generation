SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(CASE 
        WHEN LENGTH(p.p_comment) > 0 THEN LENGTH(p.p_comment) 
        ELSE NULL 
    END) AS max_comment_length,
    REGEXP_REPLACE(SUBSTRING_INDEX(p.p_name, ' ', -1), '[^a-zA-Z]', '') AS processed_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 5000.00
GROUP BY 
    p.p_name
HAVING 
    unique_suppliers > 2
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
