SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    LEFT(p.p_comment, 20) AS short_comment,
    CONCAT(CONCAT('Supplier: ', s.s_name), ', Product: ', p.p_name) AS supplier_product_info,
    SUBSTRING_INDEX(c.c_address, ',', 1) AS city
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
    p.p_brand LIKE 'Brand#%'
    AND c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey, p.p_comment, c.c_address
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
