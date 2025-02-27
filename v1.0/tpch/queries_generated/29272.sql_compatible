
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 500.00
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
ORDER BY 
    total_available_quantity DESC, short_comment;
