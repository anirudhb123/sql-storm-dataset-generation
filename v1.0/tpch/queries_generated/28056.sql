SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    l.l_shipdate,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS part_comment_excerpt
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
    p.p_name LIKE '%steel%' 
    AND s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name LIKE 'United%'
    )
GROUP BY 
    p.p_name, s.s_name, c.c_name, l.l_shipdate
HAVING 
    total_quantity > 100
ORDER BY 
    total_quantity DESC, average_discount ASC;
