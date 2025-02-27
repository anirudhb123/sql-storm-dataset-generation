WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS TotalOrders, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
)
SELECT 
    c.c_name,
    cs.TotalOrders,
    cs.TotalSpent,
    COALESCE(th.TotalSupplyCost, 0) AS SupplierCost,
    s.Level AS SupplierLevel
FROM customer c
INNER JOIN CustomerOrderStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN TopSuppliers th ON th.s_suppkey = c.c_nationkey
LEFT JOIN SupplierHierarchy s ON c.c_nationkey = s.s_suppkey
WHERE cs.TotalSpent > 1000
ORDER BY cs.TotalSpent DESC, c.c_name
FETCH FIRST 10 ROWS ONLY;
