WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > 10000.00
    UNION ALL
    SELECT sp.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.depth + 1
    FROM partsupp sp
    JOIN SupplierHierarchy sh ON sp.ps_partkey = (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_retailprice > 500.00 
        ORDER BY p.p_retailprice DESC 
        LIMIT 1
    )
    JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
)
SELECT n.n_name, SUM(sh.s_acctbal) AS total_acctbal, COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING SUM(sh.s_acctbal) > 50000.00
ORDER BY total_acctbal DESC
LIMIT 10;
