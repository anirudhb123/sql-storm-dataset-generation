SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    s.s_name AS supplier_name,
    CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand) AS part_brand_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    CASE
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name
ORDER BY 
    total_revenue DESC;
