SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_acctbal,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', r.r_name), '; ') AS nation_region
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
    p.p_retailprice > 50.00 
    AND p.p_comment LIKE '%high quality%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 10
ORDER BY 
    total_available_quantity DESC;
