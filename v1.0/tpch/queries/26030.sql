SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(CASE 
        WHEN LENGTH(s.s_name) > 20 THEN LENGTH(s.s_name) 
        ELSE NULL 
    END) AS avg_long_supplier_name_length,
    STRING_AGG(DISTINCT SUBSTRING(p.p_name, 1, 10), ', ') AS sample_product_names
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC;
