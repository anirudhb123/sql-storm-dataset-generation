SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    CONCAT('Part: ', p.p_name, ' - Supplier: ', s.s_name) AS part_supplier_info,
    SUBSTRING_INDEX(c.c_address, ',', 1) AS customer_city,
    CONCAT('Order: ', o.o_orderkey, ' - Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d')) AS order_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = s.s_nationkey AND n.n_name LIKE 'A%')
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey
HAVING 
    total_revenue > 1000
ORDER BY 
    total_revenue DESC, o.o_orderdate ASC;
