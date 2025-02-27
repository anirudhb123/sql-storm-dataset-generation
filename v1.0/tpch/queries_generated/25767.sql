SELECT 
    CONCAT('Part: ', p.p_name, ' | Container: ', p.p_container, ' | Price: $', FORMAT(p.p_retailprice, 2)) AS part_info,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
    AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN o.o_totalprice END) AS avg_building_order_price
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
    p.p_size BETWEEN 1 AND 50
GROUP BY 
    p.p_partkey, p.p_name, p.p_container, p.p_retailprice
HAVING 
    supplier_count > 5
ORDER BY 
    total_available_qty DESC;
