
SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS region_nation_info,
    LENGTH(p.p_comment) AS comment_length
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
    p.p_type LIKE '%plastic%' AND 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_partkey, 
    short_name, 
    r.r_name, 
    n.n_name,
    LENGTH(p.p_comment)
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    avg_retail_price DESC;
