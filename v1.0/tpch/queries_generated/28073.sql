SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate,
    SUBSTRING(p.p_name, 1, 10) AS short_p_name,
    REPLACE(s.s_address, 'Street', 'St') AS modified_address,
    CONCAT('Order #', o.o_orderkey, ' from ', c.c_name) AS order_summary,
    LENGTH(p.p_comment) AS comment_length,
    TRIM(REGEXP_REPLACE(r.r_name, '\\s+', ' ')) AS cleaned_region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LENGTH(p.p_name) > 10
AND 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    o.o_orderdate DESC, 
    comment_length DESC;
