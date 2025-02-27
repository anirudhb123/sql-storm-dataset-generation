
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS average_price, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    STRING_AGG(DISTINCT n.n_name, '; ') AS nations_served
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 10 
    AND p.p_retailprice BETWEEN 50.00 AND 100.00
    AND l.l_shipdate >= DATE '1997-01-01' 
GROUP BY 
    p.p_name, 
    s.s_name 
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
