SELECT 
    p.p_brand, 
    COUNT(*) AS supplier_count, 
    AVG(ps.ps_supplycost) AS avg_supplycost, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names, 
    STRING_AGG(DISTINCT CONCAT(c.c_name, ': ', o.o_orderkey), '; ') AS customer_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    p.p_type LIKE '%brass%'
GROUP BY 
    p.p_brand
HAVING 
    COUNT(*) > 5
ORDER BY 
    avg_supplycost DESC;
