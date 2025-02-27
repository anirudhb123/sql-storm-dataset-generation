WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT o.c_custkey, o.o_orderkey, ts.total_revenue,
           RANK() OVER (PARTITION BY o.c_custkey ORDER BY ts.total_revenue DESC) AS order_rank
    FROM orders o
    JOIN TotalSales ts ON o.o_orderkey = ts.o_orderkey
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name, COUNT(DISTINCT sp.s_suppkey) AS supplier_count, 
       AVG(sp.total_supplycost) AS avg_supply_cost,
       SUM(ts.total_revenue) AS total_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN RankedOrders ts ON s.s_nationkey = ts.o_orderkey
WHERE r.r_comment IS NOT NULL AND sp.total_supplycost IS NOT NULL
GROUP BY r.r_name
HAVING AVG(sp.total_supplycost) > 5000
ORDER BY total_revenue DESC;
