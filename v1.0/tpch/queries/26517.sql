SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT(n.n_name, ' - ', r.r_name) AS location,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(l.l_comment, '; ') AS comments_summary
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
    p.p_type LIKE '%brass%' 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
ORDER BY 
    total_quantity DESC, average_extended_price DESC
LIMIT 10;