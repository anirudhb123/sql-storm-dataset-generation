SELECT 
    l_shipmode,
    SUM(CASE 
        WHEN l_returnflag = 'R' THEN l_extendedprice * (1 - l_discount)
        ELSE 0 
    END) AS returned_revenue,
    SUM(CASE 
        WHEN l_returnflag = 'A' THEN l_extendedprice * (1 - l_discount)
        ELSE 0 
    END) AS active_revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '2022-01-01' 
    AND l_shipdate < DATE '2023-01-01'
GROUP BY 
    l_shipmode
ORDER BY 
    l_shipmode;
