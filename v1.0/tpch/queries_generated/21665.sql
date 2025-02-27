WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 1 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp GROUP BY ps_suppkey HAVING SUM(ps_availqty) > 1000)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment, c.c_acctbal, ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
FilteredLineitems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
    GROUP BY l.l_orderkey
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, AVG(c.c_acctbal) AS avg_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY r.r_name
)
SELECT 
    rh.s_suppkey, 
    rh.s_name, 
    rh.s_comment, 
    r.r_name AS region_name, 
    r.avg_acctbal,
    hv.o_orderkey, 
    hv.o_totalprice, 
    hv.c_mktsegment,
    COALESCE(fl.total_revenue, 0) AS total_revenue
FROM SupplierHierarchy rh
FULL OUTER JOIN RegionStats r ON rh.s_nationkey = (SELECT r2.r_regionkey FROM region r2 WHERE r2.r_name LIKE 'South%')
LEFT JOIN HighValueOrders hv ON hv.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = rh.s_suppkey)
LEFT JOIN FilteredLineitems fl ON fl.l_orderkey = hv.o_orderkey
WHERE r.avg_acctbal IS NOT NULL 
AND (COALESCE(fl.total_revenue, 0) > 10000 OR hv.rank <= 5)
ORDER BY r.r_name, hv.o_totalprice DESC, rh.s_name;
