SELECT 
    MAX(LENGTH(p.p_name)) AS max_part_name_length,
    MIN(LENGTH(p.p_name)) AS min_part_name_length,
    AVG(LENGTH(p.p_name)) AS avg_part_name_length,
    COUNT(DISTINCT p.p_brand) AS distinct_brands,
    SUM(CASE WHEN LENGTH(p.p_comment) > 0 THEN 1 ELSE 0 END) AS non_empty_comments,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_name) AS total_suppliers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON n.n_nationkey = c.c_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
GROUP BY 
    r.r_name
ORDER BY 
    max_part_name_length DESC, distinct_brands ASC;
