SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(s.s_acctbal) AS average_supplier_balance,
    MAX(p.p_retailprice) AS max_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT r.r_name, '; ') AS regions_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice) > 1000
ORDER BY 
    supplier_count DESC, total_quantity DESC;
