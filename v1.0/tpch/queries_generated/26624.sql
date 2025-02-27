SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count, 
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS total_returned_quantity, 
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
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
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 10 AND 
    AVG(p.p_retailprice) > 50.00
ORDER BY 
    supplier_count DESC, avg_retail_price ASC;
