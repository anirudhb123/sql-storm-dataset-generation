WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    INNER JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN supplier s ON s.s_suppkey = sh.s_suppkey
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 1
ORDER BY total_revenue DESC
LIMIT 10;
