SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    COUNT(l.l_linenumber) AS line_item_count,
    STRING_AGG(DISTINCT l.l_comment, '; ') AS line_comments,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date
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
    p.p_type LIKE '%metal%'
    AND c.c_mktsegment = 'BUILDING'
    AND l.l_shipmode IN ('AIR', 'RAIL')
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
