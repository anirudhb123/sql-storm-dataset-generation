SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(p.p_comment, ' ', 2) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS supplier_part_info
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
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    p.p_name, s.s_name, short_comment
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
