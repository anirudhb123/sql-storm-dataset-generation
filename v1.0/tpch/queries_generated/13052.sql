SELECT 
    ps.ps_partkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    lineitem l 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
WHERE 
    l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
GROUP BY 
    ps.ps_partkey
ORDER BY 
    revenue DESC
LIMIT 10;
