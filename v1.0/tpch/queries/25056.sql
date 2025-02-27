
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Total Cost: $', ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2)) AS benchmark_info
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
    s.s_suppkey, s.s_name, p.p_partkey, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) DESC;
