SELECT 
    s_name,
    COUNT(DISTINCT ps_partkey) AS unique_parts,
    SUM(ps_availqty) AS total_quantity,
    AVG(ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p_name, ': ', p_comment), '; ') AS part_details
FROM 
    supplier 
JOIN 
    partsupp ON s_suppkey = ps_suppkey
JOIN 
    part ON ps_partkey = p_partkey
WHERE 
    s_acctbal > 1000.00 
GROUP BY 
    s_name 
HAVING 
    COUNT(DISTINCT ps_partkey) > 5 
ORDER BY 
    total_quantity DESC 
LIMIT 10;
