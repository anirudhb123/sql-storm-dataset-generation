WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS Level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, oh.Level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND oh.Level < 5
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS TotalAvailable, AVG(ps.ps_supplycost) AS AvgCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS NumOrders, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 100
    GROUP BY c.c_custkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS SupplierRank
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    c.c_name AS CustomerName,
    oh.o_orderkey AS OrderKey,
    oh.o_totalprice AS TotalPrice,
    ps.TotalAvailable AS AvailableQuantity,
    ps.AvgCost AS AverageCost,
    rs.SupplierRank AS SupplierRanking
FROM CustomerOrderStats cos 
JOIN OrderHierarchy oh ON cos.c_custkey = oh.o_custkey
JOIN PartSupplierStats ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = oh.o_orderkey)
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = (SELECT TOP 1 ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = oh.o_orderkey) ORDER BY ps.ps_supplycost ASC)
WHERE cos.NumOrders > 5
ORDER BY oh.o_orderdate DESC, TotalPrice DESC
LIMIT 100;
