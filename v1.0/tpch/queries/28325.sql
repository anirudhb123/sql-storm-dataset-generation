
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    MAX(p.p_retailprice) AS max_price, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    REPLACE(p.p_comment, 'special', 'premium') AS updated_comment
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
    r.r_name LIKE 'Asia%'
    AND p.p_size BETWEEN 10 AND 20
GROUP BY 
    p.p_name, p.p_comment
ORDER BY 
    total_available_quantity DESC;
