SELECT 
    p.p_name, 
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
WHERE 
    li.l_shipdate >= '2023-01-01' AND li.l_shipdate < '2024-01-01'
GROUP BY 
    p.p_name
ORDER BY 
    revenue DESC
LIMIT 10;
