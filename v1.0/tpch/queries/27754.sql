
SELECT 
    s.s_name,
    s.s_address,
    CONCAT('Total Availability of ', p.p_name, ' from ', s.s_name, ' is: ', SUM(ps.ps_availqty)) AS availability_summary,
    STRING_AGG(DISTINCT n.n_name, ', ') AS supplied_nations,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS market_segments,
    MAX(o.o_orderdate) AS last_order_date,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
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
WHERE 
    p.p_name LIKE 'Rubber%'
GROUP BY 
    s.s_name, s.s_address, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    last_order_date DESC;
