SELECT 
    CONCAT_WS(' ', c.c_name, r.r_name) AS customer_region,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS unique_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%sensitive%'
GROUP BY 
    customer_region, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
