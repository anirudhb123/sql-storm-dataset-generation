SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    o.o_orderkey AS order_key,
    COUNT(l.l_orderkey) AS total_line_items,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT l.l_comment, '; ') AS line_item_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_name, s.s_name, c.c_name, n.n_name, o.o_orderkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;
