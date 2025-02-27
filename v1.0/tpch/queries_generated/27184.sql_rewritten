SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name, 
    r.r_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(l.l_quantity) AS average_quantity, 
    STRING_AGG(DISTINCT l.l_shipmode, ', ') AS unique_ship_modes
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE '%Asia%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
ORDER BY 
    total_revenue DESC;