SELECT 
    s_name AS supplier_name,
    CONCAT('Region: ', r_name, ', Nation: ', n_name) AS location,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT p_name, ', ') AS supplied_parts
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l_returnflag = 'N'
GROUP BY 
    s_name, r_name, n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;