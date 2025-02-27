WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_discount * l.l_extendedprice) AS TotalDiscount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT r.r_name, COUNT(*) AS SupplierCount, AVG(od.TotalDiscount) AS AvgTotalDiscount
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN OrderDetails od ON od.o_totalprice > 10000
GROUP BY r.r_name
HAVING COUNT(*) > 5
ORDER BY SupplierCount DESC, AvgTotalDiscount DESC;
