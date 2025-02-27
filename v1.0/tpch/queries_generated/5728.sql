WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, h.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy h ON n.n_nationkey = h.n_nationkey
)
SELECT 
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name
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
    part p ON l.l_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    n.n_regionkey IN (SELECT n_nationkey FROM nation_hierarchy)
    AND o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY 
    c.c_name, s.s_name, p.p_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC, order_count DESC;
