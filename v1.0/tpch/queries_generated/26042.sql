WITH StringProcessing AS (
    SELECT 
        p.p_name,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        UPPER(p.p_mfgr) AS upper_mfgr,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'fragile', 'sturdy') AS modified_comment,
        CONCAT(p.p_brand, ' ', p.p_type) AS brand_type,
        TRIM(p.p_container) AS container_trimmed
    FROM 
        part p
)
SELECT 
    sp.short_name,
    sp.upper_mfgr,
    sp.lower_comment,
    sp.comment_length,
    sp.modified_comment,
    sp.brand_type,
    sp.container_trimmed,
    r.r_name,
    n.n_name,
    s.s_name
FROM 
    StringProcessing sp
JOIN 
    partsupp ps ON ps.ps_partkey = (SELECT p_partkey FROM part WHERE p_name = sp.p_name LIMIT 1)
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    customer c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = ps.ps_partkey))
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    sp.comment_length > 20
ORDER BY 
    sp.container_trimmed, sp.upper_mfgr, sp.short_name;
