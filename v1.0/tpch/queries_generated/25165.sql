SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), ',', 10) AS top_suppliers,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 THEN 'High Value'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%metal%' 
    AND o.o_orderdate >= DATE '2023-01-01' 
    AND o.o_orderdate < DATE '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    total_quantity > 10
ORDER BY 
    total_quantity DESC;
