SELECT 
    n.n_name AS nation_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ': $', p.p_retailprice), ', ') AS product_details
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1996-01-01'
    AND o.o_orderdate < '1997-01-01'
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    total_revenue DESC;