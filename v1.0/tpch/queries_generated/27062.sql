SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.p_comment, ' ', 1), ' ', -1) AS first_word_comment
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND p.p_size IN (5, 10, 20)
GROUP BY 
    p.p_name, s.s_name, region_nation, first_word_comment
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC, order_count ASC;
