
SELECT 
    p.p_brand, 
    p.p_type, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    p.p_brand, p.p_type, p.p_retailprice, p.p_comment
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    supplier_count DESC, avg_retail_price DESC;
