SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
    CASE 
        WHEN p.p_size < 20 THEN 'Small'
        WHEN p.p_size BETWEEN 20 AND 50 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
WHERE 
    s.s_acctbal > 10000 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, short_comment, size_category
ORDER BY 
    total_revenue DESC
LIMIT 50;