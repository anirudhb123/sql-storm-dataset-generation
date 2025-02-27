SELECT 
    p.p_name, 
    COUNT(DISTINCT l.l_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment FROM 1 FOR 20) AS short_comment,
    CONCAT('Part Name: ', p.p_name, ', Revenue: ', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS revenue_summary,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
