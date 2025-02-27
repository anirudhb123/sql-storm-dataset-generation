SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost,
    LENGTH(MAX(p.p_comment)) AS max_comment_length,
    LENGTH(MIN(p.p_comment)) AS min_comment_length
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10 
    AND p.p_type LIKE '%wood%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
