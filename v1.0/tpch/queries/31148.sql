WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
TotalSales AS (
    SELECT l.l_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1996-12-31'
    GROUP BY l.l_partkey
)
SELECT r.r_name, 
       SUM(ts.total_sales) AS total_sales,
       COUNT(DISTINCT sp.s_suppkey) AS num_suppliers,
       AVG(sp.s_acctbal) AS avg_supplier_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier sp ON n.n_nationkey = sp.s_nationkey
LEFT JOIN TotalSales ts ON sp.s_suppkey = ts.l_partkey
WHERE r.r_comment LIKE '%environment%'
  AND (SELECT COUNT(*) FROM SupplierHierarchy sh WHERE sh.s_nationkey = n.n_nationkey) > 0
GROUP BY r.r_name
HAVING SUM(ts.total_sales) > 50000
ORDER BY total_sales DESC;