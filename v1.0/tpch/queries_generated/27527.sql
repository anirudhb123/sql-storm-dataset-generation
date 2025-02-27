SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    n.n_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS average_discount,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments,
    STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments,
    STRING_AGG(DISTINCT c.c_comment, '; ') AS customer_comments
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    p.p_name, s.s_name, c.c_name, n.n_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100 
ORDER BY 
    total_revenue DESC;
