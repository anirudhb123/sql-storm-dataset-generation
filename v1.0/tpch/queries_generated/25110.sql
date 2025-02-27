SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    COUNT(DISTINCT o.o_orderkey) AS orders_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    SUBSTRING(p.p_comment, 1, 20) AS short_comment, 
    CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name) AS descriptor
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
    p.p_size >= 10 
    AND l.l_shipdate >= '2023-01-01' 
    AND l.l_shipdate <= '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name, c.c_name
ORDER BY 
    total_revenue DESC, orders_count DESC
LIMIT 100;
