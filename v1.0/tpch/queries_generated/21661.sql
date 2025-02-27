WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS Level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT sh.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.Level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.Level < 3
),
PartAggregates AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS TotalAvailable, AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
CustomerNations AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS CustomerCount
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS RegionName,
    COALESCE(SUM(pa.TotalAvailable), 0) AS TotalAvailableParts,
    COALESCE(SUM(pa.AvgSupplyCost), 0) AS AvgSupplyCost,
    (SELECT COUNT(*) FROM SupplierHierarchy) AS ActiveSuppliers,
    (SELECT COUNT(*) FROM OrderSummary WHERE TotalRevenue > 10000) AS HighValueOrders,
    cn.n_name AS NationName,
    cn.CustomerCount
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN partsupp ps ON n.n_nationkey = ps.ps_suppkey
LEFT JOIN PartAggregates pa ON ps.ps_partkey = pa.p_partkey
LEFT JOIN CustomerNations cn ON cn.n_name = n.n_name
GROUP BY r.r_name, cn.n_name, cn.CustomerCount
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY RegionName DESC, CustomerCount DESC;
