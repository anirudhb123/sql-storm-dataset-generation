SELECT 
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    ROUND(AVG(p.p_retailprice), 2) AS average_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations
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
    p.p_size > 10 
    AND r.r_name LIKE '%West%'
GROUP BY 
    p.p_brand
HAVING 
    SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
