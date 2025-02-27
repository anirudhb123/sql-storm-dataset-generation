SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    CONCAT('Available: ', SUM(ps.ps_availqty), ', Orders: ', COUNT(DISTINCT o.o_orderkey)) AS summary,
    CASE 
        WHEN SUM(ps.ps_supplycost) > 10000 THEN 'High Cost Supplier'
        ELSE 'Standard Supplier'
    END AS supplier_cost_category
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey 
JOIN 
    orders o ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate >= DATE '1997-01-01' 
GROUP BY 
    p.p_name, s.s_name 
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, unique_customers DESC;