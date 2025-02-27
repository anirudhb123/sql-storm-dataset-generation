SELECT 
    CONCAT_WS(' ', s.s_name, s.s_address) AS supplier_details,
    p.p_name AS part_name,
    SUBSTRING_INDEX(p.p_comment, ' ', 5) AS comment_excerpt,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    r.r_name AS region_name
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
    p.p_brand LIKE 'Brand#%'
    AND o.o_orderdate >= DATE('2022-01-01')
    AND o.o_orderdate < DATE('2023-01-01')
GROUP BY 
    supplier_details, part_name, comment_excerpt, r.r_name
HAVING 
    total_quantity > 100
ORDER BY 
    avg_extended_price DESC
LIMIT 10;
