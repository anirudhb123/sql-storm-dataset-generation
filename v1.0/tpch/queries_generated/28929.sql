SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Total Cost: $', 
           ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_cost),
    s.s_nationkey,
    n.n_name,
    r.r_name
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
    LENGTH(p.p_name) > 10
GROUP BY 
    s.s_suppkey, p.p_partkey, n.n_name, r.r_name
ORDER BY 
    total_cost DESC
LIMIT 10;
