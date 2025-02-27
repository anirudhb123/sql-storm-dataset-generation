SELECT 
    p.p_name, 
    s.s_name as supplier_name, 
    c.c_name as customer_name, 
    COUNT(DISTINCT o.o_orderkey) as order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) as total_revenue, 
    SUBSTRING_INDEX(CONCAT_WS(' ', p.p_comment, s.s_comment, c.c_comment), ' ', 10) as combined_comments 
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
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey 
HAVING 
    total_revenue > 10000 
ORDER BY 
    total_revenue DESC, order_count ASC;
