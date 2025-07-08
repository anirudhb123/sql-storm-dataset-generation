
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= sh.s_acctbal
), 
AvgPartPrice AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_price
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
HighPricedParts AS (
    SELECT p.p_partkey, p.p_name
    FROM part p
    JOIN AvgPartPrice a ON p.p_partkey = a.ps_partkey
    WHERE a.avg_price > 25.00
), 
RecentOrders AS (
    SELECT o.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(sh.s_acctbal) AS total_acctbal,
    COUNT(DISTINCT pp.p_partkey) AS high_priced_part_count,
    COUNT(DISTINCT ro.o_orderkey) AS recent_order_count,
    COALESCE(NULLIF(AVG(sh.level), 0), -1) AS avg_hierarchy_level
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN HighPricedParts pp ON sh.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pp.p_partkey)
LEFT JOIN RecentOrders ro ON s.s_suppkey IN (SELECT li.l_suppkey FROM lineitem li WHERE li.l_orderkey = ro.o_orderkey)
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY total_acctbal DESC;
