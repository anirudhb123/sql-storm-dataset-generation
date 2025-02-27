
SELECT 
    p.p_partkey,
    LENGTH(p.p_name) AS name_length,
    UPPER(p.p_mfgr) AS mfgr_upper,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'O') AS open_orders,
    MAX(p.p_retailprice) OVER (PARTITION BY p.p_type) AS max_price_by_type,
    REPLACE(p.p_container, 'Box', 'Container') AS updated_container
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
    p.p_size > 10 AND 
    LOWER(p.p_comment) LIKE '%quality%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_comment, p.p_container, p.p_type
ORDER BY 
    name_length DESC, 
    supplier_count DESC;
