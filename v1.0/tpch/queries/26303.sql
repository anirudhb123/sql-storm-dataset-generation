SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_type, ')'), ', ') AS part_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name IN ('USA', 'Canada', 'Mexico')
GROUP BY 
    s.s_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
