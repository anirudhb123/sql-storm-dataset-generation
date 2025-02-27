SELECT 
    CONCAT(s.s_name, ' (', LOWER(s.s_address), ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT CASE 
        WHEN LENGTH(p.p_name) > 20 THEN SUBSTRING(p.p_name, 1, 20) || '...' 
        ELSE p.p_name END ORDER BY p.p_name SEPARATOR ', '), ',', 10) AS top_parts
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O' 
    AND s.s_comment NOT LIKE '%customer%'
    AND p.p_comment LIKE '%metal%'
GROUP BY 
    s.s_suppkey
ORDER BY 
    total_revenue DESC
LIMIT 5;
