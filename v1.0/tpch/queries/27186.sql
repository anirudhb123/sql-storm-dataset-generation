SELECT 
    p.p_name, 
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(p.p_retailprice) AS avg_retail_price,
    MAX(l.l_discount) AS max_discount,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS comments_summary
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
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND l.l_shipdate >= '1997-01-01' 
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_retail_price ASC;