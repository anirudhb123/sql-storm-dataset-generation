WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 5000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
),
AggregatedSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    INNER JOIN RecentOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY l.l_partkey
),
SupplierSales AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ag.total_sales) AS total_supplier_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN AggregatedSales ag ON ps.ps_partkey = ag.l_partkey
    GROUP BY s.s_suppkey
)
SELECT n.n_name, SUM(ss.total_supplier_cost) AS region_total_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierSales ss ON ss.total_supplier_cost IS NOT NULL
GROUP BY n.n_name
ORDER BY region_total_cost DESC
LIMIT 10;
