SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    STRING_AGG(CONCAT(s.s_name, ' (', s.s_address, ', ', s.s_phone, ')'), '; ') AS suppliers_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    LEFT(p.p_comment, 20) AS short_comment,
    CASE 
        WHEN SUM(l.l_quantity) > 1000 THEN 'High Volume'
        WHEN SUM(l.l_quantity) BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    total_revenue DESC;
