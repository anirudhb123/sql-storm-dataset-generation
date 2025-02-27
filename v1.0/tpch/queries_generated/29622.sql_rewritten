SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey AS order_key, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CONCAT(l.l_shipmode, '(', l.l_shipinstruct, ')'), ', ') AS shipping_details,
    MAX(l.l_shipdate) AS latest_ship_date,
    MIN(l.l_shipdate) AS earliest_ship_date
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_type LIKE 'wood%'
AND 
    o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 10;