SELECT 
    LEFT(p.p_name, 20) AS short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    r.r_name AS region_name
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
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND LENGTH(p.p_comment) > 10
GROUP BY 
    short_name, r.r_name
HAVING 
    SUM(l.l_extendedprice) > 10000
ORDER BY 
    supplier_count DESC, total_quantity DESC;