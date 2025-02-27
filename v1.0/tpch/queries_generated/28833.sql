SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_totalprice AS order_total,
    o.o_orderdate AS order_date,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT(SUBSTRING(p.p_name, 1, 5), '...', SUBSTRING(p.p_name, LENGTH(p.p_name) - 4)) AS abbreviated_part_name,
    (SELECT COUNT(*) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey) AS suppliers_in_nation
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
    p.p_comment LIKE '%fragile%'
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_totalprice, o.o_orderdate
ORDER BY 
    total_revenue DESC, order_date ASC;
