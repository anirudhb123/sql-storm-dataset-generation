SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT CONCAT_WS(' | ', l.l_returnflag, l.l_linestatus, l.l_shipmode), ', ') AS flags_status_modes,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Value'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS revenue_category
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
WHERE 
    p.p_size = (SELECT MAX(p2.p_size) FROM part p2)
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 1
ORDER BY 
    total_revenue DESC, part_name;
