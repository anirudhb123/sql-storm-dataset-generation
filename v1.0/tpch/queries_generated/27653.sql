SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_price,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON o.o_custkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE 'Special%' 
    AND o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    AND s.s_acctbal > 500.00
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name
HAVING 
    total_available_quantity > 1000
ORDER BY 
    avg_order_price DESC, total_orders DESC
LIMIT 10;
