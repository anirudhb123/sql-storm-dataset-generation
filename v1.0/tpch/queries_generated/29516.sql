SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT(s.s_address, ', ', n.n_name) AS supplier_address,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS comment_excerpt
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'Europe%')
AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address, n.n_name
HAVING 
    total_revenue > 5000
ORDER BY 
    total_revenue DESC, average_quantity ASC
LIMIT 10;
