SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS average_order_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    MAX(length(s.s_comment)) AS max_supplier_comment_length,
    MIN(length(p.p_comment)) AS min_part_comment_length,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS supplier_part_summary
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_size > 10 
AND 
    o.o_orderdate > '1997-01-01' 
GROUP BY 
    s.s_name, p.p_name 
ORDER BY 
    total_available_quantity DESC, unique_customers DESC;