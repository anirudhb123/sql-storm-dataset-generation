SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    COUNT(o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Supplier:', s.s_name, '; Part:', p.p_name, '; Customer:', c.c_name) AS detailed_info,
    SUBSTRING_INDEX(REPLACE(p.p_comment, 'good', 'excellent'), ' ', 5) AS modified_comment
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
AND 
    s.s_acctbal > 1000.00 
GROUP BY 
    p.p_name, s.s_name, c.c_name 
HAVING 
    total_orders > 10 
ORDER BY 
    total_revenue DESC 
LIMIT 20;
