SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS average_supplycost, 
    CONCAT(n.n_name, ' (', r.r_name, ')') AS nation_region,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00
    AND p.p_type LIKE '%metal%'
GROUP BY 
    short_name, nation_region
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    average_supplycost DESC;
