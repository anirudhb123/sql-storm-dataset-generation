SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(CAST(SUBSTRING_INDEX(s.s_name, ' ', -1) AS CHAR)) AS avg_supplier_name_length,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, r.r_name
HAVING 
    total_revenue > 1000000
ORDER BY 
    total_revenue DESC;
