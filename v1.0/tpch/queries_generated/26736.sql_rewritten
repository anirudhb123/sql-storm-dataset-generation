SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', r.r_name, ')'), '; ') AS supplier_nations
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
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    supplier_count DESC, total_available_quantity ASC;