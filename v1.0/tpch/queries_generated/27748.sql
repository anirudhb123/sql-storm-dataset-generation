SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    LEFT(r.r_name, 10) AS region_name,
    CONCAT(p.p_mfgr, ' - ', p.p_type) AS part_description,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Activity'
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity' 
    END AS activity_level
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
    p.p_name, s.s_name, r.r_name, p.p_mfgr, p.p_type
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
