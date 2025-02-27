SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    TO_CHAR(o.o_orderdate, 'YYYY-MM') AS order_month
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
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    supplier_info, order_month
ORDER BY 
    total_revenue DESC, order_month ASC;
