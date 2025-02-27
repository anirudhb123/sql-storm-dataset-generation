SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ', ', r.r_name) AS supplier_info,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS part_comments
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
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    r.r_name LIKE 'S%' 
    AND p.p_size BETWEEN 10 AND 20 
    AND l.l_shipdate >= '1997-01-01'
GROUP BY 
    supplier_info
ORDER BY 
    total_parts DESC, avg_extended_price DESC;