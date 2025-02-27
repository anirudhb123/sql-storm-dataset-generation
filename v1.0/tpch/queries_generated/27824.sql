SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT p.p_comment ORDER BY p.p_partkey SEPARATOR '; '), '; ', 5) AS sample_comments
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND p.p_name LIKE '%widget%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
HAVING 
    revenue > 1000
ORDER BY 
    revenue DESC, o.o_orderdate DESC;
