SELECT 
    LOWER(SUBSTRING(p_name, 1, 10)) AS short_name,
    COUNT(DISTINCT s_nationkey) AS supplier_count,
    STRING_AGG(DISTINCT s_name, ', ') AS supplier_names,
    AVG(ps_supplycost) AS avg_supply_cost,
    (SELECT COUNT(DISTINCT c_custkey) 
     FROM customer 
     WHERE c_comment LIKE '%' || LOWER(p_comment) || '%') AS related_customer_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE 'Extra%')
GROUP BY 
    short_name
HAVING 
    AVG(ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    supplier_count DESC;
