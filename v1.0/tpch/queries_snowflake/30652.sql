
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_revenue,
    RANK() OVER (PARTITION BY p.p_type ORDER BY AVG(ps.ps_supplycost) DESC) AS type_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN customer c ON c.c_nationkey = s.s_nationkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
  AND l.l_shipdate >= '1997-01-01' 
  AND l.l_shipdate < (SELECT MAX(l2.l_shipdate) FROM lineitem l2 WHERE l2.l_returnflag = 'N')
  AND (c.c_acctbal IS NOT NULL OR c.c_mktsegment <> 'AUTO')
  AND EXISTS (SELECT 1 FROM SupplierHierarchy WHERE s.s_suppkey = SupplierHierarchy.s_suppkey)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY type_rank, discounted_revenue DESC
LIMIT 50;
