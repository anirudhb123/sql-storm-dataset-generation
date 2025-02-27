SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Region: ', r.r_name) AS benchmark_output,
    COUNT(DISTINCT p.p_partkey) AS parts_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 20 
    AND r.r_name LIKE 'Asia%' 
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    s.s_name, p.p_name, r.r_name
ORDER BY 
    total_available_quantity DESC
LIMIT 100;