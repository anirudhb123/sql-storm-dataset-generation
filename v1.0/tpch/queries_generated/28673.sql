SELECT 
    SUBSTRING(p_name, 1, 20) AS short_name,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    SUM(ps_availqty) AS total_availability,
    AVG(p_retailprice) AS average_price,
    r_name AS region_name
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    nation ON s_nationkey = n_nationkey
JOIN 
    region ON n_regionkey = r_regionkey
WHERE 
    p_type LIKE '%brass%'
    AND p_comment NOT LIKE '%old%'
GROUP BY 
    short_name, region_name
HAVING 
    total_availability > 1000
ORDER BY 
    average_price DESC, region_name ASC;
