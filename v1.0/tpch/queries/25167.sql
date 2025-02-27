
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity) AS total_quantity_sold, 
    AVG(l.l_extendedprice) AS avg_price_per_line,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_details,
    CONCAT('Type: ', p.p_type, ' | Size: ', p.p_size, ' | Container: ', p.p_container) AS part_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_type, p.p_size, p.p_container
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity_sold DESC;
