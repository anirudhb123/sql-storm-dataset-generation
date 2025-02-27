SELECT 
    p.p_name, 
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderstatus) > 1 THEN 'Multiple Statuses' 
        ELSE 'Single Status'
    END AS order_status_category
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC, order_count DESC;
