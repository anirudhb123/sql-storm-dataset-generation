SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Revenue'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1995-01-01' AND 
    l.l_shipdate <= '1995-12-31' AND 
    o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_quantity DESC, 
    revenue_category;