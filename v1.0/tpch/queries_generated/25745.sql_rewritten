SELECT 
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' - ', r.r_name), '; ') AS customer_region_summary,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order
FROM 
    customer AS c
JOIN 
    orders AS o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;