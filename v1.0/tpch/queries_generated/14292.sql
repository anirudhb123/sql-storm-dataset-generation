SELECT 
    l.linestatus,
    SUM(l.quantity) AS total_quantity,
    SUM(l.extendedprice * (1 - l.discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS num_orders
FROM 
    lineitem l
JOIN 
    orders o ON l.orderkey = o.orderkey
WHERE 
    l.shipdate >= DATE '2023-01-01' AND l.shipdate < DATE '2023-12-31'
GROUP BY 
    l.linestatus
ORDER BY 
    l.linestatus;
