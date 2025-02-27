SELECT 
    l.l_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    o.o_orderdate
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
GROUP BY 
    l.l_orderkey, o.o_orderdate
ORDER BY 
    total_revenue DESC
LIMIT 100;
