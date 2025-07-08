
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_avail_qty,
    ROUND(AVG(p.p_retailprice), 2) AS avg_retail_price,
    LISTAGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS supplier_nations,
    COALESCE(REGEXP_REPLACE(LISTAGG(DISTINCT CASE 
        WHEN p.p_type LIKE '%rubber%' THEN p.p_comment 
        ELSE '' END, ', ') WITHIN GROUP (ORDER BY p.p_comment), ', $', ''), 'No rubber parts', 'No comments') AS rubber_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_avail_qty DESC, avg_retail_price ASC;
