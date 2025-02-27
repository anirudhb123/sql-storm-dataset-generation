SELECT 
    p.p_name, 
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
WHERE 
    ls.l_shipdate >= '2023-01-01' AND ls.l_shipdate < '2024-01-01'
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
