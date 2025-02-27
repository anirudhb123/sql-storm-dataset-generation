SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    SUBSTRING_INDEX(SUBSTRING_INDEX(p.p_comment, ' ', 5), ' ', -5) AS comment_excerpt,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_size > 10 AND
    s.s_acctbal > 5000
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    total_available_quantity DESC, avg_retail_price ASC;
