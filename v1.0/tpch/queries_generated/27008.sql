SELECT 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(s.s_acctbal) AS average_supplier_balance, 
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied 
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LOWER(p.p_name) LIKE '%steel%' 
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    s.s_suppkey, s.s_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5 
ORDER BY 
    total_parts_supplied DESC, average_supplier_balance DESC;
