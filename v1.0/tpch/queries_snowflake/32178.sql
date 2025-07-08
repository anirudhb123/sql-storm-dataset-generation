WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
GROUP BY 
    p.p_partkey, p.p_name, p.p_size
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5 AND 
    AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp) 
ORDER BY 
    total_revenue DESC, revenue_rank
LIMIT 10;