WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS TotalOrders, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS TotalAvailable
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopProducts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(TotalAvailable, 0) AS TotalAvailable
    FROM part p
    LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100
    ORDER BY TotalAvailable DESC
    LIMIT 10
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    co.TotalOrders, 
    co.TotalSpent, 
    th.p_name, 
    th.TotalAvailable, 
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY co.TotalSpent DESC) AS Rank
FROM CustomerOrders co
JOIN Customer c ON co.c_custkey = c.c_custkey
CROSS JOIN TopProducts th
WHERE c.c_acctbal IS NOT NULL AND co.TotalOrders > 0
  AND EXISTS (
      SELECT 1 
      FROM SupplierHierarchy sh 
      WHERE sh.s_nationkey = c.c_nationkey 
      AND sh.Level < 3
  )
ORDER BY c.c_custkey, Rank;
