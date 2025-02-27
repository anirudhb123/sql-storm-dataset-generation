WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           CASE 
              WHEN SUM(ps.ps_availqty) > 100 THEN 'High Availability'
              WHEN SUM(ps.ps_availqty) IS NULL THEN 'No Availability'
              ELSE 'Low Availability'
           END AS AvailabilityStatus
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           COUNT(o.o_orderkey) AS OrderCount,
           AVG(o.o_totalprice) AS AvgOrderPrice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') OR o.o_totalprice IS NOT NULL
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
RegionStatistics AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS NationCount,
           SUM(COALESCE(c.c_acctbal, 0)) AS TotalAccountBalance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
OrderLineMetrics AS (
    SELECT o.o_orderkey,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS TotalReturned,
           COUNT(l.l_orderkey) AS TotalLineItems,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice) DESC) AS LineRank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, 
       SUM(sd.TotalCost) AS TotalSupplierCost,
       AVG(co.AvgOrderPrice) AS AvgCustomerOrderPrice,
       MAX(ols.TotalReturned) AS MaxReturnedItems
FROM RegionStatistics r
LEFT JOIN SupplierDetails sd ON r.NationCount > 1 AND sd.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN CustomerOrders co ON r.TotalAccountBalance > 0
LEFT JOIN OrderLineMetrics ols ON ols.LineRank <= 10
WHERE r.TotalAccountBalance IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT sd.s_suppkey) > 5
ORDER BY AvgCustomerOrderPrice DESC, TotalSupplierCost ASC
FETCH FIRST 100 ROWS ONLY;
