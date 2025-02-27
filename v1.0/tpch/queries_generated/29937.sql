SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(CASE 
            WHEN LENGTH(ps.ps_comment) > 100 THEN 1 
            ELSE 0 
        END) AS comments_over_100,
    AVG(ROUND(l.l_extendedprice * (1 - l.l_discount), 2)) AS avg_price_after_discount,
    SUBSTR(p.p_comment, 1, 15) || '...' AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    supplier_count DESC, avg_price_after_discount ASC;
