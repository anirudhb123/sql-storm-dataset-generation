
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS unique_ship_modes,
    COUNT(DISTINCT l.l_linenumber) AS line_item_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Order Status: ', o.o_orderstatus, ', Priority: ', o.o_orderpriority) AS order_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_comment LIKE '%fragile%'
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    p.p_name, s.s_name, n.n_name, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_orderpriority
ORDER BY 
    total_revenue DESC
LIMIT 100;
