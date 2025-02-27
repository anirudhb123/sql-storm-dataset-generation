SELECT 
    COUNT(*) AS total_orders, 
    SUM(o_totalprice) AS total_revenue, 
    AVG(o_totalprice) AS avg_order_value
FROM 
    orders 
WHERE 
    o_orderdate BETWEEN '2022-01-01' AND '2022-12-31';
