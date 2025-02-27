
SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    CONCAT('Total price for ', SUBSTRING(p_name, 1, 10), ' is: ', 
        CAST(SUM(l_extendedprice * (1 - l_discount)) AS VARCHAR(50))) AS total_price,
    CASE 
        WHEN SUM(l_quantity) > 100 THEN 'High Demand' 
        ELSE 'Regular Demand' 
    END AS demand_category,
    r_name AS region_name
FROM 
    part
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    lineitem ON ps_partkey = l_partkey
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    customer ON o_custkey = c_custkey
JOIN 
    nation ON c_nationkey = n_nationkey
JOIN 
    region ON n_regionkey = r_regionkey
WHERE 
    p_name LIKE 'Rubber%'
GROUP BY 
    short_name, r_name
HAVING 
    COUNT(DISTINCT s_suppkey) > 10
ORDER BY 
    SUM(l_extendedprice * (1 - l_discount)) DESC;
