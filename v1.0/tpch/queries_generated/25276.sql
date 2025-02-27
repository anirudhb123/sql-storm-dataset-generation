SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name,
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name, ', Customer: ', c.c_name, 
           ' (OrderID: ', o.o_orderkey, ') - ', o.o_orderstatus) AS order_detail,
    LEFT(o.o_orderdate, 7) AS order_month,
    SUM(l.l_quantity) AS total_quantity,
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
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    AND s.s_comment NOT LIKE '%special%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_orderdate
ORDER BY 
    total_revenue DESC, order_month ASC;
