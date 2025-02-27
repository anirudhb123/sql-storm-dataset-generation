WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost, COUNT(*) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal, SUM(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END) AS valid_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_name, p.p_brand, p.p_type, p.p_retailprice, 
       COALESCE(ps.total_supplycost, 0) AS total_supplycost, 
       ns.supplier_count AS nation_supplier_count,
       sh.level AS supplier_hierarchy_level
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN NationSummary ns ON p.p_brand = ns.n_nationkey
LEFT JOIN SupplierHierarchy sh ON ns.supplier_count = sh.supplier_count
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type LIKE 'S%' 
) AND p.p_size BETWEEN 10 AND 20
ORDER BY p.p_retailprice DESC, ns.total_acctbal DESC
FETCH FIRST 100 ROWS ONLY;
