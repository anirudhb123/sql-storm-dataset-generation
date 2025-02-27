SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_location,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(CASE 
        WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice 
        ELSE NULL 
    END) AS avg_filled_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_container LIKE 'SM%'
GROUP BY 
    s.s_name, n.n_name, r.r_name
ORDER BY 
    total_sales DESC, total_orders DESC
LIMIT 10;