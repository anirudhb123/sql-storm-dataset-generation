SELECT 
    p.p_name, 
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Size: ', CAST(p.p_size AS CHAR(10))) AS size_info,
    s.s_name AS supplier_name,
    REPLACE(s.s_address, 'Street', 'St.') AS address_short,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_totalprice) AS max_order_value,
    REGEXP_REPLACE(p.p_type, '([a-z])([A-Z])', '\\1 \\2') AS formatted_type
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
    s.s_acctbal > 10000
GROUP BY 
    p.p_name, 
    short_comment, 
    size_info, 
    supplier_name, 
    address_short
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    max_order_value DESC;
