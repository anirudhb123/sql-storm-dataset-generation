SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    AVG(CASE 
            WHEN LENGTH(s.s_comment) > 50 THEN LENGTH(s.s_comment) 
            ELSE 0 
        END) AS avg_long_comment_length,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    SUM(l.l_discount * l.l_extendedprice) AS total_discounted_price
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100 
    AND LENGTH(p.p_comment) > 10
GROUP BY 
    s.s_name, p.p_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_discounted_price DESC;
