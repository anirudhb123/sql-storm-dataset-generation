SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_location,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(p.p_retailprice) AS max_price,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS short_comment
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    supplier_location
HAVING 
    total_orders > 10 AND total_revenue > 10000
ORDER BY 
    total_revenue DESC;
