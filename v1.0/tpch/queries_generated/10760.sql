SELECT 
    COUNT(*) AS total_orders,
    SUM(o_totalprice) AS total_revenue,
    AVG(o_totalprice) AS average_order_value,
    MIN(o_orderdate) AS first_order_date,
    MAX(o_orderdate) AS last_order_date
FROM 
    orders
WHERE 
    o_orderdate BETWEEN '2023-01-01' AND '2023-12-31';
