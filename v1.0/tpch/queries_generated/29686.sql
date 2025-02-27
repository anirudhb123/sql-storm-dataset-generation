SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_part_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, '(', p.p_brand, ')'), ', ') AS part_names
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_type LIKE '%metal%'
    AND p.p_size > 10
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC, avg_part_price ASC;
