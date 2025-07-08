WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_retailprice < 300)
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 5
)
SELECT n.n_name AS nation, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY supplier_count DESC, avg_acctbal DESC
LIMIT 10;
