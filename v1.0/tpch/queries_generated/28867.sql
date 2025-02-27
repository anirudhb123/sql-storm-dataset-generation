SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    r.r_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name) AS detail_info,
    CASE 
        WHEN LENGTH(p.p_comment) > 10 THEN 'Comment is lengthy'
        ELSE 'Comment is short'
    END AS comment_length,
    REPLACE(UPPER(p.p_type), ' ', '_') AS formatted_type,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_size >= 10 AND 
    s.s_acctbal > 100.00 
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, p.p_comment 
HAVING 
    COUNT(o.o_orderkey) > 5 
ORDER BY 
    total_quantity DESC 
LIMIT 50;
