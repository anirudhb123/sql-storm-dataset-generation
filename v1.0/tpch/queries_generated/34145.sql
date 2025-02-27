WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(NULLIF(r.r_name, ''), 'Unknown Region') AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.s_acctbal) FILTER (WHERE s.s_acctbal > 0) AS avg_active_balance,
    MAX(l.l_quantity) OVER (PARTITION BY l.l_orderkey) AS max_line_quantity,
    STRING_AGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    AND o.o_orderstatus = 'O'
    AND l.l_returnflag IS NULL
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC
LIMIT 50;
