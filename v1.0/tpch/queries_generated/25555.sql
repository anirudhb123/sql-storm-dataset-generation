SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(p.p_retailprice) AS average_retail_price, 
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info
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
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 5000
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_retail_price DESC;
