SELECT 
    p.p_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    c.c_name AS customer_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    STRING_AGG(DISTINCT CONCAT(l.l_shipinstruct, ' : ', l.l_comment), '; ') AS instructions_comments,
    STRING_AGG(DISTINCT SUBSTRING(p.p_comment, 1, 20), ', ') AS part_comments_fragmented
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_size > 10 
GROUP BY 
    p.p_name, s.s_name, n.n_name, c.c_name
ORDER BY 
    total_orders DESC, total_quantity DESC
LIMIT 50;
