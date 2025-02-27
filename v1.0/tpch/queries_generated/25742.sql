SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name, ' | ', 
           'Cost: ', FORMAT(ps.ps_supplycost, 2), ' | ', 
           'Comment: ', SUBSTRING(ps.ps_comment, 1, 50)) AS detail
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND p.p_container LIKE '%box%' 
    AND s.s_comment ILIKE '%reliable%'
ORDER BY 
    s.s_name ASC, 
    ps.ps_supplycost DESC
LIMIT 20;
