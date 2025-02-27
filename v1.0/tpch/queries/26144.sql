SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_sales,
    AVG(l.l_extendedprice) AS average_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' - ', s.s_name), '; ') AS part_supplier_list
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 10 AND p.p_retailprice BETWEEN 50.00 AND 500.00
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_sales DESC;
