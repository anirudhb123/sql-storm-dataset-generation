WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    UNION ALL
    SELECT r.r_regionkey, CONCAT(r.r_name, ' > ', rh.r_name), level + 1
    FROM region_hierarchy rh
    JOIN nation n ON rh.r_regionkey = n.n_regionkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_discount) AS avg_discount,
    MAX(l.l_shipdate) AS last_ship_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Has Orders' 
        ELSE 'No Orders' 
    END AS order_status,
    rh.r_name AS region_path
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region_hierarchy rh ON n.n_regionkey = rh.r_regionkey
GROUP BY 
    c.c_name, rh.r_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
