
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    CONCAT(s.s_name, ' (', s.s_address, ')') AS supplier_info,
    CASE 
        WHEN MAX(o.o_totalprice) < 1000 THEN 'Low Value Order'
        WHEN MAX(o.o_totalprice) BETWEEN 1000 AND 5000 THEN 'Medium Value Order'
        ELSE 'High Value Order'
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%fragile%' 
    AND s.s_comment LIKE '%urgent%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1998-10-01'
GROUP BY 
    p.p_name, s.s_name, s.s_address
ORDER BY 
    total_available_quantity DESC, total_orders DESC;
