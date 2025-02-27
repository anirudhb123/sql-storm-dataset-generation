WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 0 AS Level
    FROM customer
    WHERE c_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.Level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey <> ch.c_custkey
)
, OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS RecentOrder
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
, SupplierCosts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT ch.c_name, 
       r.r_name AS Region,
       SUM(os.TotalRevenue) AS TotalRevenue,
       (SELECT COUNT(DISTINCT ps_partkey) FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = ch.c_nationkey)) AS DistinctPartsSupplied,
       CASE 
           WHEN SUM(os.TotalRevenue) IS NULL THEN 'No Orders' 
           ELSE CASE 
              WHEN SUM(os.TotalRevenue) > (SELECT AVG(TotalRevenue) FROM OrderSummary) THEN 'Above Average'
              ELSE 'Below Average'
           END 
       END AS RevenueComparison
FROM CustomerHierarchy ch
JOIN OrderSummary os ON ch.c_custkey = os.o_custkey
JOIN nation n ON ch.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierCosts sc ON sc.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = os.o_custkey ORDER BY ps.ps_availqty DESC LIMIT 1)
WHERE r.r_name LIKE '%North%' OR r.r_name LIKE 'S%'
GROUP BY ch.c_name, r.r_name
ORDER BY TotalRevenue DESC NULLS LAST
LIMIT 10
OFFSET (SELECT COUNT(*) FROM customer WHERE c_acctbal IS NULL);
