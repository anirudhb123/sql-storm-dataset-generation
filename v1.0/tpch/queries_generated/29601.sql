SELECT 
    CONCAT(s.s_name, ' (', SUBSTRING(s.s_address, 1, 10), '...)') AS supplier_info,
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(DATEDIFF(l.l_shipdate, o.o_orderdate)) AS avg_ship_days,
    GROUP_CONCAT(DISTINCT CONCAT(n.n_name, ' - ', r.r_name) ORDER BY n.n_name SEPARATOR '; ') AS nation_region
FROM 
    supplier s
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    s.s_suppkey, p.p_partkey
HAVING 
    total_orders > 10 AND total_revenue > 10000.00
ORDER BY 
    total_revenue DESC;
