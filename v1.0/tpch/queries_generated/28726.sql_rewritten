SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, '|', s.s_phone), ', ') AS suppliers_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
AND 
    p.p_container LIKE '%BOX%'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_quantity DESC, 
    p.p_name;