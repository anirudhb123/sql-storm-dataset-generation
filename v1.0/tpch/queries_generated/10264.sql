SELECT 
    SUM(l_extendedprice) * (1 - l_discount) AS revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '2021-01-01'
    AND l_shipdate < DATE '2021-02-01'
GROUP BY 
    l_returnflag, l_linestatus
ORDER BY 
    l_returnflag, l_linestatus;
