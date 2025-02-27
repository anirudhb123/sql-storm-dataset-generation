SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name, ', Nation: ', n.n_name) AS full_description,
    CASE 
        WHEN LENGTH(p.p_comment) > 20 THEN SUBSTR(p.p_comment, 1, 20) || '...' 
        ELSE p.p_comment 
    END AS truncated_comment,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100.00 
    AND s.s_acctbal > 500.00 
    AND n.n_name LIKE 'A%'
GROUP BY 
    p.p_name, s.s_name, n.n_name, p.p_comment
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    customer_count DESC, p.p_name ASC;
