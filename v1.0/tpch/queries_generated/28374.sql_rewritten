SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    MAX(CASE WHEN l.l_returnflag = 'Y' THEN l.l_extendedprice ELSE 0 END) AS max_returned_value,
    MIN(l.l_tax) AS min_tax_value,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_comment), ', ') AS supplier_comments
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 1 AND 50
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_quantity DESC;