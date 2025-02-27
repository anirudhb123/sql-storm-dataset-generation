SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_served
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_type LIKE '%brass%'
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    total_available_quantity DESC, average_extended_price DESC;