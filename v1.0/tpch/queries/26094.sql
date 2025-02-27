SELECT 
    CONCAT('Supplier Name: ', s.s_name, ', Parts Supplied: ', COUNT(ps.ps_partkey), 
           ', Total Supply Cost: $', ROUND(SUM(ps.ps_supplycost), 2), 
           ', Region: ', r.r_name) AS benchmark_output
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.s_acctbal > 1000 AND 
    (LOWER(s.s_comment) LIKE '%preferred%' OR LOWER(s.s_comment) LIKE '%urgent%')
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(ps.ps_partkey) > 5
ORDER BY 
    SUM(ps.ps_supplycost) DESC;
