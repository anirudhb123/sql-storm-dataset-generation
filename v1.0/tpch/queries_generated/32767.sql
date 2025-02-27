WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY o.o_orderkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
)
SELECT
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS TotalAvailable,
    AVG(ps.ps_supplycost) AS AvgSupplyCost,
    COUNT(DISTINCT l.l_orderkey) AS DistinctOrders,
    (SELECT COUNT(*) FROM HighValueCustomers) AS HighValueCustomerCount,
    (SELECT GROUP_CONCAT(DISTINCT sh.s_name ORDER BY sh.Level DESC)
     FROM SupplierHierarchy sh
     WHERE sh.s_nationkey = p.p_mfgr
    ) AS SupplierNames
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
GROUP BY p.p_partkey, p.p_name
HAVING TotalAvailable > 500 
   OR EXISTS (SELECT 1 FROM OrderSummary os WHERE os.TotalRevenue > 10000 AND os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey))
ORDER BY TotalAvailable DESC, AvgSupplyCost ASC;
