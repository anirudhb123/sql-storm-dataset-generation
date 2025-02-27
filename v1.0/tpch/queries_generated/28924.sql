SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', s.s_name, ')'), '; ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_type LIKE '%brass%' 
    AND s.s_acctbal > 5000 
    AND n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%North%')
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 3
ORDER BY 
    total_available_quantity DESC;
