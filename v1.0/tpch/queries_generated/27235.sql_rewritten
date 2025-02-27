SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_info,
    SUBSTRING(p.p_name, 1, 20) AS short_part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_price,
    MAX(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) END) AS max_discounted_price,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS shipping_methods
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE '%wood%' 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    s.s_name, n.n_name, r.r_name, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5;