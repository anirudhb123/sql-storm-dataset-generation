SELECT 
    SUBSTRING(p_name, 1, 20) AS short_name,
    CONCAT('Supplier: ', s_name, ', Nation: ', n_name) AS supplier_nation_info,
    p_brand,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    COUNT(DISTINCT o_orderkey) AS number_of_orders,
    MAX(o_orderdate) AS last_order_date
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n_name LIKE 'A%'
    AND o_orderstatus = 'O'
    AND l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    short_name, supplier_nation_info, p_brand
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
