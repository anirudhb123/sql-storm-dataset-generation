SELECT 
    l_orderkey, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '2022-01-01' AND l_shipdate < DATE '2022-02-01'
GROUP BY 
    l_orderkey
ORDER BY 
    revenue DESC
LIMIT 10;
