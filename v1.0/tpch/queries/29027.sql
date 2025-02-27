
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    COUNT(l.l_orderkey) AS line_item_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments,
    SUBSTRING(o.o_comment, 1, 50) AS truncated_order_comment
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND c.c_mktsegment = 'BUILDING'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, c.c_name, o.o_orderkey, p.p_comment, o.o_comment
ORDER BY 
    total_extended_price DESC
LIMIT 100;
