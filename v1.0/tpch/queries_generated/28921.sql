SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    AVG(DATEDIFF(l.l_shipdate, o.o_orderdate)) AS avg_ship_time,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate >= '2023-01-01' 
    AND l.l_shipdate < '2023-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC
LIMIT 50;
