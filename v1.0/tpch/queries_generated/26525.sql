SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT_WS(' ', s.s_name, '(', s.s_phone, ')') AS supplier_info,
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_sales,
    DATE_FORMAT(o.o_orderdate, '%Y-%m') AS order_month,
    r.r_name AS region
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%'
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, supplier_info, order_month, r.r_name
ORDER BY 
    total_sales DESC, order_month ASC
LIMIT 100;
