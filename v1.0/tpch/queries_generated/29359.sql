SELECT 
    LOWER(SUBSTR(p_name, 1, 20)) AS short_name,
    CONCAT(UPPER(p_brand), ' ', r_name) AS brand_region,
    TRIM(REPLACE(REPLACE(p_comment, ' ', ''), '.', '')) AS cleaned_comment,
    COUNT(DISTINCT s_suppkey) AS supplier_count,
    MAX(p_retailprice) AS max_price,
    AVG(p_size) AS avg_size
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p_type LIKE '%metal%'
    AND s_acctbal > 5000
GROUP BY 
    short_name, brand_region, cleaned_comment
HAVING 
    avg_size > 10
ORDER BY 
    max_price DESC
LIMIT 100;
