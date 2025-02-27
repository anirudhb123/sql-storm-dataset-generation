SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    COUNT(DISTINCT l.l_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ' - ', p.p_name) AS supplier_part_info
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
    c.c_mktsegment = 'BUILDING' 
    AND p.p_size >= 10 
    AND o.o_orderstatus = 'O' 
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    total_revenue > 1000
ORDER BY 
    total_revenue DESC;
