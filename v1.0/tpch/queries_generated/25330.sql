SELECT 
    s_name,
    COUNT(DISTINCT o_orderkey) AS order_count,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    SUBSTRING_INDEX(SUBSTRING_INDEX(s_comment, 'special', -1), ' ', 1) AS special_keyword
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
    o.o_orderdate >= '2023-01-01' 
    AND o.o_orderdate < '2023-12-31'
    AND s_comment LIKE '%special%'
GROUP BY 
    s_name
HAVING 
    total_revenue > 100000
ORDER BY 
    order_count DESC, total_revenue DESC;
