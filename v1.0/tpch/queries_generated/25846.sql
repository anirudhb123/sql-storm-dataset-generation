SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity) AS total_quantity_sold, 
    AVG(o.o_totalprice) AS avg_order_price,
    CONCAT('Supplied by ', GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', ')) AS suppliers,
    CASE 
        WHEN AVG(o.o_totalprice) > 500 THEN 'High Value' 
        WHEN AVG(o.o_totalprice) BETWEEN 200 AND 500 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS order_value_category
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
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey
HAVING 
    total_quantity_sold > 100
ORDER BY 
    total_quantity_sold DESC;
