SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderdate, 
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING_INDEX(p.p_comment, ' ', 3) AS short_comment,
    CONCAT(SUBSTRING(s.s_name, 1, 10), '...') AS short_supp_name,
    CASE 
        WHEN LENGTH(p.p_name) > 30 THEN 'Long Name'
        ELSE 'Short Name'
    END AS name_length_category
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_comment LIKE '%premium%'
    AND c.c_mktsegment = 'Wholesale'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderdate
HAVING 
    total_revenue > 10000
ORDER BY 
    total_orders DESC, total_revenue DESC;
