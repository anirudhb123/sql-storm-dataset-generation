SELECT 
    s.s_name AS supplier_name,
    SUM(CASE WHEN p.p_size <= 10 THEN ps.ps_availqty ELSE 0 END) AS small_parts_qty,
    SUM(CASE WHEN p.p_size > 10 AND p.p_size <= 20 THEN ps.ps_availqty ELSE 0 END) AS medium_parts_qty,
    SUM(CASE WHEN p.p_size > 20 THEN ps.ps_availqty ELSE 0 END) AS large_parts_qty,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE NULL END) AS avg_total_price_open,
    AVG(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE NULL END) AS avg_total_price_filled,
    STRING_AGG(p.p_name, ', ') AS part_names_concatenated
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
WHERE 
    s.s_comment LIKE '%popular%' 
GROUP BY 
    s.s_name
ORDER BY 
    total_orders DESC, 
    supplier_name ASC
LIMIT 10;
