
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
AverageOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS TotalSold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > 100
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 50000
)
SELECT 
    c.c_name AS CustomerName,
    sh.s_name AS HighValueSupplier,
    AVG(a.TotalValue) AS AverageOrderValue,
    p.TotalSold AS TotalPartsSold
FROM CustomerOrders c
JOIN AverageOrderValue a ON c.OrderCount > 0
JOIN FilteredSuppliers sh ON sh.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
JOIN TopParts p ON p.TotalSold > 50
WHERE sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
GROUP BY c.c_name, sh.s_name, p.TotalSold
ORDER BY AverageOrderValue DESC, TotalPartsSold ASC
LIMIT 10;
