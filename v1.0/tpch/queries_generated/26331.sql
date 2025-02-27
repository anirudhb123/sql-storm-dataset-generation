SELECT 
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    LEFT(SUBSTRING_INDEX(s.s_name, ' ', 1), 5) AS supplier_first_name,
    CONCAT(SUBSTRING(s.s_address, 1, 20), '...') AS short_address,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
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
    p.p_name LIKE 'green%'
    AND s.s_comment NOT LIKE '%special%'
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name, supplier_first_name, short_address
HAVING 
    total_quantity > 1000
ORDER BY 
    total_revenue DESC, total_quantity ASC;
