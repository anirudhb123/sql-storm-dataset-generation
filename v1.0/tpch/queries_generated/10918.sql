SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_sales 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
WHERE 
    o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31' 
GROUP BY 
    p.p_partkey, p.p_name 
ORDER BY 
    total_sales DESC 
LIMIT 100;
