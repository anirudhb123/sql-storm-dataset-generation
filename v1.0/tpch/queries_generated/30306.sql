WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name,
    MAX(CASE WHEN s.s_acctbal IS NULL THEN 'No Account Balance' ELSE CAST(s.s_acctbal AS CHAR) END) AS max_supplier_balance,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice) DESC) AS rank_within_region
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND (l.l_shipdate >= '2023-01-01' OR l.l_shipdate IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) > 5000
ORDER BY 
    region_name, total_revenue DESC
LIMIT 50;
