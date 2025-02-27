SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT(s.s_address, ', ', n.n_name, ', ', r.r_name) AS full_address,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS unique_comments
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
    l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1998-01-01'
GROUP BY 
    p.p_name, 
    s.s_name, 
    s.s_address, 
    n.n_name, 
    r.r_name
ORDER BY 
    total_available_quantity DESC, 
    avg_extended_price DESC
LIMIT 100;