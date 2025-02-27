WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, sh.Level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey AND s2.s_acctbal < sh.s_acctbal
)
SELECT r.r_name, COUNT(DISTINCT sh.s_suppkey) AS SupplierCount,
    SUM(CASE WHEN p.p_size IS NULL THEN 0 ELSE p.p_retailprice END) AS TotalRetailPrice,
    STRING_AGG(DISTINCT p.p_name || ': ' || p.p_retailprice::text, ', ') AS PartDetails,
    (SELECT AVG(c.c_acctbal) 
     FROM customer c 
     WHERE c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 5000)) AS CustomerAvgBalance
FROM nation n
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > (
    SELECT COUNT(*) FROM supplier s1 WHERE s1.s_acctbal IS NOT NULL AND s1.s_acctbal < 1000
) OR EXISTS (
    SELECT 1 FROM customer c WHERE c.c_nationkey = n.n_nationkey AND c.c_mktsegment = 'BUILDING'
    LIMIT 1
)
ORDER BY SupplierCount DESC, TotalRetailPrice DESC NULLS LAST;
