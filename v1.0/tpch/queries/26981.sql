SELECT 
    p.p_name AS part_name,
    p.p_mfgr AS manufacturer,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS average_returned_qty,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied
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
    p.p_retailprice > 20.00
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    p.p_name, p.p_mfgr, s.s_name
ORDER BY 
    total_revenue DESC, part_name ASC
LIMIT 100;
