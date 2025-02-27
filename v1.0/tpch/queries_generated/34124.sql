WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_quantity) AS TotalQuantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY o.o_orderkey, o.o_totalprice
),
AvgSupplierCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS AvgCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    r.r_name AS Region,
    n.n_name AS Nation,
    COALESCE(s.s_name, 'Unknown') AS SupplierName,
    AVG(s.s_acctbal) AS AverageSupplierBalance,
    (SELECT COUNT(*) FROM HighValueOrders) AS HighValueOrderCount,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS TotalSales,
    SUM(CASE WHEN l.l_tax IS NULL THEN 0 ELSE l.l_tax END) AS TotalTax,
    COUNT(DISTINCT o.o_orderkey) as UniqueOrderCount
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY p.p_name, r.r_name, n.n_name, s.s_name
ORDER BY TotalSales DESC, AverageSupplierBalance DESC
LIMIT 10;
