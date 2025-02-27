SELECT 
    p.p_name AS product_name, 
    s.s_name AS supplier_name, 
    CONCAT(r.r_name, ' - ', n.n_name) AS location, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(p.p_retailprice) AS avg_retail_price, 
    STRING_AGG(DISTINCT p.p_comment, '; ') AS aggregated_comments
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
    p.p_type LIKE 'Metal%'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC;
