SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_availqty,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    n.n_name AS nation,
    r.r_name AS region,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
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
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
GROUP BY 
    p.p_name, n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_availqty DESC
LIMIT 10;
