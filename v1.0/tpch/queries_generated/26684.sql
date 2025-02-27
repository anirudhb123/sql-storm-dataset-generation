SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    CONCAT('Order Date: ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD'), ', Status: ', o.o_orderstatus) AS order_details,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    COUNT(DISTINCT r.r_regionkey) AS unique_regions_count
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 50.00 
    AND o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderdate, o.o_orderstatus
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
