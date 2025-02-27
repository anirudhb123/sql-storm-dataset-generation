SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
            WHEN p.p_size < 15 THEN 1 
            WHEN p.p_size BETWEEN 15 AND 30 THEN 2 
            ELSE 3 
        END) AS size_category,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%'
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC, p.p_name;