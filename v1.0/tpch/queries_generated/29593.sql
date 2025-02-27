SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_address), '; ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_name
HAVING 
    AVG(l.l_extendedprice) > (SELECT AVG(l2.l_extendedprice) FROM lineitem l2)
ORDER BY 
    supplier_count DESC, returns DESC
LIMIT 10;
