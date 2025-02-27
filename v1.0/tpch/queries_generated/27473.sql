SELECT 
    p.p_name,
    COUNT(DISTINCT l.orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTR(s.s_name, 1, 3) AS short_supplier_name,
    TRIM(reg.r_name) AS region_name,
    CONCAT('Order Count: ', COUNT(DISTINCT l.orderkey)) AS order_info
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region reg ON n.n_regionkey = reg.r_regionkey
WHERE 
    p.p_retailprice > 100.00
    AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    p.p_name, short_supplier_name, region_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
