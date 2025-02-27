SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', n.n_name) AS supplier_customer_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    LEFT(l.l_comment, 20) AS comment_excerpt
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    AND s.s_comment LIKE '%urgent%'
GROUP BY 
    c.c_name, s.s_name, n.n_name, LEFT(l.l_comment, 20)
ORDER BY 
    total_revenue DESC
LIMIT 10;