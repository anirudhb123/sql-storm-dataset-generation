SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name, 
    SUM(ps.ps_availqty) AS total_available_qty,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS aggregated_comments,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Nation: ', n.n_name) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 50
GROUP BY 
    p.p_name, 
    s.s_name, 
    n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_qty DESC, 
    p.p_name ASC;
