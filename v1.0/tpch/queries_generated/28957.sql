SELECT 
    p.p_name, 
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_totalprice) AS max_order_value,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS unique_order_statuses
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retialprice > 100.00
    AND s.s_acctbal > 500.00
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name, supplier_info
ORDER BY 
    total_available_quantity DESC, avg_order_value DESC;
