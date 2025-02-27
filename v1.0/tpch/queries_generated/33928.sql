WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
BestSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, sh.level, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    GROUP BY sh.s_suppkey, sh.s_name, sh.level
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
),
HighValueCustomers AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING total_spent > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT DISTINCT
    c.c_name AS CustomerName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalSales,
    s.s_name AS SupplierName,
    sh.level AS SupplierLevel,
    r.r_name AS CustomerRegion
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN BestSuppliers s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE c.c_custkey IN (SELECT c_custkey FROM HighValueCustomers)
AND (s.total_supply_cost IS NOT NULL OR s.total_supply_cost < 5000)
GROUP BY c.c_custkey, c.c_name, s.s_name, sh.level, r.r_name
ORDER BY TotalSales DESC, TotalOrders DESC;
