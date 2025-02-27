SELECT 
    p.p_name AS part_name,
    p.p_size AS part_size,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS average_supplier_balance,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_served
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%special%'
    AND l.l_shipmode IN ('TRUCK', 'SHIP')
GROUP BY 
    p.p_name, p.p_size, s.s_name, c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;
