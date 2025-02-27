WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN SupplierHierarchy sh ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 10)
)
SELECT r.r_name, COUNT(DISTINCT sh.s_suppkey) AS total_suppliers, SUM(ps.ps_availqty) AS total_available_quantity
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE sh.level <= 3
GROUP BY r.r_name
ORDER BY total_available_quantity DESC;
