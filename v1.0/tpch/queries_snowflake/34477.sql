
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount,
    SUM(ps.ps_availqty) AS TotalAvailableQuantity,
    AVG(ps.ps_supplycost) AS AverageSupplyCost,
    LISTAGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS NationsSupplied,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS PartRank
FROM part p
LEFT OUTER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT OUTER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT OUTER JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_retailprice > 100.00
AND EXISTS (
    SELECT 1 FROM lineitem l
    WHERE l.l_partkey = p.p_partkey
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1997-01-01'
)
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
AND AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY PartRank
LIMIT 10;
