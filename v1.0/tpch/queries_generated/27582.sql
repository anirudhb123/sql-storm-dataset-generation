SELECT 
    CONCAT_WS(' - ', s.s_name, p.p_name, c.c_name) AS supplier_part_customer,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS truncated_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    AVG(l.l_quantity) AS avg_quantity
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_comment LIKE '%quality%'
    AND p.p_type LIKE 's%' 
GROUP BY 
    supplier_part_customer, truncated_comment
ORDER BY 
    revenue DESC, last_ship_date ASC
LIMIT 10;
