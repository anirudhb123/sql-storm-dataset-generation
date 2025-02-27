SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Total Cost: $', ROUND(SUM(ps_supplycost * ps_availqty), 2)) AS benchmark_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name IN ('USA', 'Germany', 'France') 
    AND p.p_size BETWEEN 10 AND 50
GROUP BY 
    s.suppkey, p.p_partkey
HAVING 
    SUM(ps_availqty) > 100
ORDER BY 
    Total_Cost DESC;
