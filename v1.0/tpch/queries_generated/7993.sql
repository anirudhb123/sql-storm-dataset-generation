WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100.00)
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT r.r_name AS Region, n.n_name AS Nation, COUNT(DISTINCT sh.s_suppkey) AS SupplierCount
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name, n.n_name
ORDER BY Region, SupplierCount DESC
LIMIT 10;
