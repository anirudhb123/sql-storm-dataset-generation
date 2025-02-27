SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        ELSE 'Low Volume' 
    END AS volume_category
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
    p.p_retailprice > 50.00 
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    short_comment
ORDER BY 
    total_revenue DESC, 
    total_orders DESC;
