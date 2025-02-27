SELECT 
    CONCAT(s.s_name, ' (', r.r_name, ')') AS supplier_region,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT SUBSTRING(p.p_comment, 1, 20), ', ') AS sample_comments
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_size > 10 AND 
    s.s_acctbal > 1000.00
GROUP BY 
    supplier_region
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_available_quantity DESC;
