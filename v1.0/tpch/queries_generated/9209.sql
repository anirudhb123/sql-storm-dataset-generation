WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23')
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT n.n_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acctbal
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY total_acctbal DESC
LIMIT 10;
