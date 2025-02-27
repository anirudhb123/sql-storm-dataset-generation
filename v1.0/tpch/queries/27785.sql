
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ', ', s.s_phone, ')'), '; ') AS supplier_details,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN AVG(ps.ps_supplycost) > 100 THEN 'High Cost'
        WHEN AVG(ps.ps_supplycost) BETWEEN 50 AND 100 THEN 'Medium Cost'
        ELSE 'Low Cost'
    END AS cost_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10 AND 
    p.p_name LIKE '%widget%'
GROUP BY 
    p.p_name, 
    short_comment
ORDER BY 
    supplier_count DESC, total_available_quantity DESC;
