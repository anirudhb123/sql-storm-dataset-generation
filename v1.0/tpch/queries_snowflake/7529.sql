WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), NationSummary AS (
    SELECT n.n_regionkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS SupplierCount, SUM(sd.TotalSupplyCost) AS RegionSupplyCost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
    GROUP BY n.n_regionkey, n.n_name
), CustomerOrderSummary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS TotalOrders, SUM(o.o_totalprice) AS TotalOrderValue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
), FinalSummary AS (
    SELECT ns.n_name AS NationName, 
           ns.SupplierCount, 
           ns.RegionSupplyCost, 
           cos.TotalOrders, 
           cos.TotalOrderValue
    FROM NationSummary ns
    JOIN CustomerOrderSummary cos ON ns.n_regionkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = cos.c_nationkey)
)
SELECT NationName, 
       SupplierCount, 
       RegionSupplyCost, 
       TotalOrders, 
       TotalOrderValue,
       (SELECT AVG(TotalSupplyCost) FROM SupplierDetails) AS AvgSupplierCost
FROM FinalSummary
WHERE TotalOrderValue > (SELECT AVG(TotalOrderValue) FROM CustomerOrderSummary)
ORDER BY TotalOrderValue DESC;
