SELECT 
    CONCAT(s.s_name, ' (' ,s.s_suppkey, ')') AS supplier_info,
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment
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
    s.s_acctbal > 1000 
    AND o.o_orderstatus = 'O' 
    AND p.p_type LIKE '%metal%'
GROUP BY 
    supplier_info, p.p_name
HAVING 
    total_quantity > 500
ORDER BY 
    total_quantity DESC;
