SELECT 
    COUNT(*) AS total_orders, 
    SUM(o_totalprice) AS total_revenue 
FROM 
    orders 
WHERE 
    o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' 
    AND o_orderstatus = 'O' 
GROUP BY 
    o_orderpriority 
ORDER BY 
    total_revenue DESC;
