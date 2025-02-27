SELECT 
    CONCAT('Supplier: ', s_name, ' | Part: ', p_name, ' | Available Quantity: ', ps_availqty) AS supply_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    MAX(l_shipdate) AS last_shipped,
    MIN(l_shipdate) AS first_shipped
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > 1000
    AND l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    s.s_suppkey, p.p_partkey
ORDER BY 
    total_revenue DESC, last_shipped DESC
LIMIT 10;
