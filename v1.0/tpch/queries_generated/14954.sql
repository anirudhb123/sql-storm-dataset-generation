SELECT 
    l_orderkey, 
    COUNT(*) AS line_count, 
    SUM(l_extendedprice) AS total_revenue 
FROM 
    lineitem 
WHERE 
    l_shipdate >= DATE '2022-01-01' 
    AND l_shipdate < DATE '2023-01-01' 
GROUP BY 
    l_orderkey 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
