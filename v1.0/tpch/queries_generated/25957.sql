SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    SUM(l.l_discount * l.l_extendedprice) AS total_discounted_price,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), ', ', 5) AS top_suppliers
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
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (p.p_comment LIKE '%green%' OR p.p_comment LIKE '%small%')
GROUP BY 
    p.p_name
HAVING 
    total_available_qty > 100
ORDER BY 
    total_discounted_price DESC
LIMIT 10;
