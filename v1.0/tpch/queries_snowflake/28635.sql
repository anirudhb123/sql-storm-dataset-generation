
SELECT 
    p.p_name, 
    s.s_name AS supplier_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount, 
    CONCAT('Supplier: ', s.s_name, ' supplies part: ', p.p_name) AS supplier_part_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_container LIKE '%box%' 
    AND s.s_comment LIKE '%trusted%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    AVG(l.l_extendedprice * (1 - l.l_discount)) DESC;
