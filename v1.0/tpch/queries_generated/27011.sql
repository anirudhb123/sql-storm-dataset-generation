SELECT 
    p.p_partkey, 
    SUBSTRING(p.p_name, 1, 10) AS short_name, 
    CONCAT('Supplier: ', s.s_name, ' | Price: ', FORMAT(ps.ps_supplycost, 2)) AS supply_info, 
    LENGTH(p.p_comment) AS comment_length, 
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 1000 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, short_name, supply_info, comment_length
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    comment_length DESC, supply_info;
