SELECT 
    p.p_name,
    CONCAT(s.s_name, ' - ', n.n_name) AS supplier_nation,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE 0 
    END) AS total_returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS average_order_value,
    GROUP_CONCAT(DISTINCT CONCAT(o.o_orderdate, ': ', o.o_orderpriority) ORDER BY o.o_orderdate ASC) AS order_dates_priorities
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
WHERE 
    o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    AND p.p_type LIKE '%plastic%'
GROUP BY 
    p.p_name, supplier_nation
HAVING 
    total_returned_quantity > 0
ORDER BY 
    average_order_value DESC, p.p_name ASC;
