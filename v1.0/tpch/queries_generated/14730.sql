SELECT 
    l_shipmode, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '2021-01-01' AND l_shipdate < DATE '2022-01-01'
GROUP BY 
    l_shipmode
ORDER BY 
    revenue DESC;
