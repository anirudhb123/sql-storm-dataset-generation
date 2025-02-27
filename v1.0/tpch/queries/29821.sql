SELECT 
    SUBSTRING(p_name, 1, 20) AS truncated_part_name,
    COUNT(DISTINCT l_orderkey) AS order_count,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT s_name, ', ') AS supplier_names,
    r_name AS region_name,
    MIN(l_shipdate) AS first_ship_date,
    MAX(l_shipdate) AS last_ship_date,
    AVG(ps_supplycost) AS average_supply_cost
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
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%metal%'
    AND l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    truncated_part_name, region_name
HAVING 
    COUNT(DISTINCT l_orderkey) > 10
ORDER BY 
    total_revenue DESC;