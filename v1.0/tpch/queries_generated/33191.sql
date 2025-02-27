WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           1 AS level, CAST(s_name AS VARCHAR(255)) AS path
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           sh.level + 1,
           CAST(sh.path || ' -> ' || s.s_name AS VARCHAR(255))
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank,
    LISTAGG(DISTINCT sh.path, '; ') WITHIN GROUP (ORDER BY sh.level) AS supplier_paths
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%Africa%')
GROUP BY n.n_name
HAVING COUNT(s.s_suppkey) > 5
ORDER BY total_supply_cost DESC;
