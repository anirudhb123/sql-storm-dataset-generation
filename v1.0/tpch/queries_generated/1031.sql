WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS OrderCount,
           SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN RankedOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           COUNT(l.l_orderkey) AS OrderCount,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT c.c_name AS CustomerName,
       COALESCE(SUM(co.TotalSpent), 0) AS TotalCustomerSpent,
       COALESCE(SUM(pd.TotalRevenue), 0) AS TotalPartRevenue,
       sp.TotalSupplyCost AS SupplierCost,
       CASE 
           WHEN SUM(co.TotalSpent) > 10000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS CustomerValue
FROM CustomerOrders co
FULL OUTER JOIN PartDetails pd ON co.OrderCount > 0
FULL OUTER JOIN SupplierParts sp ON pd.OrderCount > 0
GROUP BY c.c_name, sp.TotalSupplyCost
HAVING (COALESCE(SUM(co.TotalSpent), 0) > 0 OR COALESCE(SUM(pd.TotalRevenue), 0) > 0)
ORDER BY TotalCustomerSpent DESC, CustomerName;
