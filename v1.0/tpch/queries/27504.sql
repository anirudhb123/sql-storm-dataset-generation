SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    l.l_orderkey AS line_order_key,
    COUNT(*) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END) AS avg_return_quantity,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', s.s_name, ')'), '; ') AS part_supplier_list,
    CONCAT(r.r_name, ': ', r.r_comment) AS region_info
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
AND 
    o.o_orderstatus IN ('F', 'O')
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, l.l_orderkey, r.r_name, r.r_comment
ORDER BY 
    total_revenue DESC
LIMIT 50;