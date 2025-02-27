
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(CONCAT('Region: ', r.r_name, ' - Comment: ', r.r_comment), '; ') AS region_comments,
    SUBSTRING(p.p_comment, 1, 20) AS abbreviated_comment
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
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC;
