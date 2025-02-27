SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    LEFT(p.p_comment, 15) AS short_comment,
    CONCAT(LEFT(s.s_address, 20), '...', ' from ', SUBSTRING(n.n_name, 1, 10)) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    YEAR(o.o_orderdate) AS order_year,
    COUNT(l.l_orderkey) AS line_item_count
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
    r.r_name LIKE 'Europe%' 
    AND o.o_orderstatus = 'O' 
    AND l.l_discount BETWEEN 0.05 AND 0.2
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, p.p_comment, n.n_name, o.o_orderdate
HAVING 
    total_revenue > 50000
ORDER BY 
    order_year DESC, total_revenue DESC;
