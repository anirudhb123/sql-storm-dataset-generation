SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue, 
    o_orderstatus 
FROM 
    lineitem 
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey 
WHERE 
    l_shipdate >= '2023-01-01' AND l_shipdate < '2024-01-01' 
GROUP BY 
    o_orderstatus 
ORDER BY 
    revenue DESC;
