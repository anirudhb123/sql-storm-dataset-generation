SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
ORDER BY 
    supplier_count DESC, 
    total_available_quantity DESC;