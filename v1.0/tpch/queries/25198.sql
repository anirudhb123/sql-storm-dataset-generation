SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info,
    REGEXP_REPLACE(p.p_mfgr, '^(.{3}).*$', '\\1**') AS truncated_mfgr,
    COUNT(o.o_orderkey) AS order_count,
    AVG(l.l_discount) AS average_discount,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
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
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 10 
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_nationkey, p.p_comment, p.p_mfgr
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    order_count DESC, average_discount ASC;