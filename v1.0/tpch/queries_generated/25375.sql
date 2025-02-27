SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS location,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(AVG(l.l_extendedprice), 2) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p.p_comment, ', ') AS part_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10 AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, n.n_name
ORDER BY 
    total_quantity DESC, avg_extended_price DESC;
