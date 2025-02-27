SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_extended_price_after_discount,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1998-01-01'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_available_quantity DESC;