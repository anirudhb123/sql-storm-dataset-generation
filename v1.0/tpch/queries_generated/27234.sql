SELECT 
    CONCAT(s.s_name, ' supplies ', COUNT(DISTINCT ps.ps_partkey), ' different parts') AS supplier_summary,
    r.r_name AS region,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    average_price DESC;
