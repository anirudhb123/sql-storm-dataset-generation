SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(p.p_retailprice) AS avg_retail_price, 
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', n.n_comment), '; ') AS nation_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 5000
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 2
ORDER BY 
    supplier_count DESC, 
    avg_retail_price ASC;
