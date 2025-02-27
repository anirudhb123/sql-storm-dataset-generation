SELECT 
    s.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_quantity) AS avg_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    DATE_TRUNC('month', o.o_orderdate) AS order_month
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
WHERE 
    s.s_acctbal > 1000 AND
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, order_month
HAVING 
    AVG(l.l_quantity) > 10
ORDER BY 
    total_revenue DESC, order_count DESC;