SELECT 
    p.p_name,
    s.s_name,
    n.n_name AS supplier_nation,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    AVG(o.o_totalprice) AS avg_order_price,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT CONCAT('Order Key: ', o.o_orderkey, ' - Priority: ', o.o_orderpriority), '; ') AS order_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%steel%' 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, avg_order_price DESC;
