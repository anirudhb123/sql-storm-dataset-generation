WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS Level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.regionkey, r.r_name, rh.Level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS TotalSupplyCost,
           AVG(s.s_acctbal) AS AvgAccountBalance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS TotalOrders,
           SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemValue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_shipdate) AS LineItemRank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'O'
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT rh.r_name, cs.c_name, ss.TotalSupplyCost, cs.TotalSpent,
           od.TotalLineItemValue,
           CASE 
               WHEN cs.TotalSpent IS NULL THEN 'No Orders'
               WHEN cs.TotalSpent > ss.TotalSupplyCost THEN 'Spent More Than Supplies'
               ELSE 'Spent Less Than or Equal to Supplies'
           END AS SpendingStatus
    FROM RegionHierarchy rh
    LEFT JOIN CustomerOrderStats cs ON rh.r_regionkey = cs.c_custkey % 5
    LEFT JOIN SupplierStats ss ON ss.s_suppkey = cs.TotalOrders % 10
    LEFT JOIN OrderDetails od ON od.o_orderkey = cs.TotalOrders
)
SELECT *
FROM FinalReport
WHERE SpendingStatus IS NOT NULL
ORDER BY r_name, c_name;
