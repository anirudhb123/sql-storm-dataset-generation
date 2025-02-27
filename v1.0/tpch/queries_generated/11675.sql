SELECT 
    ps.partkey,
    SUM(ps.ps_availqty) AS total_availqty,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AMERICA')
GROUP BY 
    ps.ps_partkey
ORDER BY 
    total_availqty DESC
LIMIT 10;
