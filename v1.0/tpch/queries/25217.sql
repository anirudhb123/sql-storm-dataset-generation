SELECT 
    CONCAT(c.c_name, ' from ', n.n_name, ', ', r.r_name) AS customer_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.r_name = 'ASIA' 
    AND l.l_returnflag = 'N'
GROUP BY 
    c.c_name, n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
