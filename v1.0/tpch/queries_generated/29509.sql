SELECT 
    CONCAT(s_name, ' from ', n_name, ' produces ', 
           SUBSTRING_INDEX(p_name, ' ', 1), 
           ' of type ', p_type, 
           ' in size ', CAST(p_size AS CHAR), 
           ' at price ', FORMAT(p_retailprice, 2)
          ) AS product_info,
    COUNT(DISTINCT c_custkey) AS customer_count,
    SUM(o_totalprice) AS total_sales
FROM 
    supplier 
JOIN 
    nation ON s_nationkey = n_nationkey 
JOIN 
    partsupp ON s_suppkey = ps_suppkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    lineitem ON l_partkey = p_partkey 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
WHERE 
    r_name LIKE 'ASIA%' 
GROUP BY 
    s_name, n_name, p_name, p_type, p_size, p_retailprice
ORDER BY 
    total_sales DESC 
LIMIT 10;
