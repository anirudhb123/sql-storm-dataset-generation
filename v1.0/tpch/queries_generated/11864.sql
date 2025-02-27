SELECT 
    l_shipmode,
    COUNT(*) AS total_orders,
    SUM(l_extendedprice) AS total_revenue
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    l_shipmode
ORDER BY 
    total_orders DESC;
