SELECT 
    l_shipmode, 
    COUNT(*) AS count_order 
FROM 
    lineitem 
WHERE 
    l_shipdate >= DATE '2023-01-01' 
    AND l_shipdate < DATE '2024-01-01' 
GROUP BY 
    l_shipmode 
ORDER BY 
    count_order DESC;
