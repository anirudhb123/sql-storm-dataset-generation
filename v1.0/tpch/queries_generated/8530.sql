WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, sh.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN SupplierHierarchy sh ON sh.s_suppkey = ps.ps_suppkey
    WHERE p.p_size > 20 AND sh.level < 5
)

SELECT sh.nation_name, COUNT(*) AS supplier_count, AVG(sh.s_acctbal) AS avg_acctbal
FROM SupplierHierarchy sh
GROUP BY sh.nation_name
HAVING COUNT(*) > 1
ORDER BY avg_acctbal DESC
LIMIT 10;
