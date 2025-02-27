SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.p_comment, ' ', 3), ' ', -3) AS comment_excerpt,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info
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
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, p.p_name ASC;
