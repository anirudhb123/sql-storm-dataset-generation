SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    COUNT(l.l_orderkey) AS lineitem_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT l.l_comment, '; ') AS combined_comments
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
    p.p_mfgr LIKE 'Manufacturer%' AND
    c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    COUNT(l.l_orderkey) > 5 AND
    SUM(l.l_extendedprice) > 1000.00
ORDER BY 
    total_extended_price DESC;
