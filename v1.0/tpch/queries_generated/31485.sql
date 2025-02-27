WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 3
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY SupplierCount DESC
    LIMIT 5
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_brand,
    COALESCE(ao.TotalSales, 0) AS TotalSales,
    th.n_name AS TopNation,
    sh.s_name AS HierarchySupplier
FROM part ph
LEFT JOIN AggregatedOrders ao ON ph.p_partkey = ao.o_orderkey
LEFT JOIN TopNations th ON ph.p_partkey = th.n_nationkey
LEFT JOIN SupplierHierarchy sh ON th.n_nationkey = sh.s_nationkey
WHERE ph.p_retailprice > 20.00
  AND (sh.Level IS NULL OR sh.Level <= 2)
  AND EXISTS (
      SELECT 1
      FROM partsupp ps
      WHERE ps.ps_partkey = ph.p_partkey AND ps.ps_availqty > 100
  )
ORDER BY TotalSales DESC, ph.p_name ASC;
