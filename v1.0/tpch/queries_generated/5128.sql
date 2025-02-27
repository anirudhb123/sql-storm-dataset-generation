WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 3
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
), NationalSales AS (
    SELECT n.n_name, SUM(co.TotalSpent) AS TotalSales
    FROM nation n
    JOIN customerorders co ON n.n_nationkey = co.c_custkey
    GROUP BY n.n_name
), TopProducts AS (
    SELECT p.p_name, SUM(l.l_extendedprice) AS TotalSales
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_name
    ORDER BY TotalSales DESC
    LIMIT 10
)
SELECT sh.s_name AS SupplierName, n.n_name AS Nation, ns.TotalSales AS NationTotalSales, tp.p_name AS TopProductName
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN NationalSales ns ON n.n_nationkey = ns.n_nationkey
CROSS JOIN TopProducts tp
ORDER BY ns.TotalSales DESC, sh.Level, tp.TotalSales DESC
LIMIT 20;
