SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT p.p_comment ORDER BY p.p_comment SEPARATOR '; '), '; ', 5) AS truncated_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey
HAVING 
    total_revenue > 1000
ORDER BY 
    total_revenue DESC, order_count DESC;
