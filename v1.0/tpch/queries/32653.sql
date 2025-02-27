
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 0 AS hierarchy_level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),

RegionSupplierCounts AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),

OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_part_count, 
           o.o_orderdate, o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus 
),

RankedOrders AS (
    SELECT os.o_orderkey, os.total_revenue, os.unique_part_count, 
           RANK() OVER (PARTITION BY os.o_orderstatus ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderSummary os
),

FinalResults AS (
    SELECT rsc.r_name, rsc.supplier_count, ro.total_revenue, ro.unique_part_count,
           CASE WHEN ro.revenue_rank <= 10 THEN 'Top 10' ELSE 'Others' END AS revenue_category
    FROM RegionSupplierCounts rsc
    LEFT JOIN RankedOrders ro ON rsc.supplier_count = (SELECT COUNT(DISTINCT s.s_suppkey)
                                                         FROM supplier s
                                                         JOIN nation n ON s.s_nationkey = n.n_nationkey
                                                         WHERE n.n_regionkey = rsc.r_regionkey)
)

SELECT r_name, supplier_count, SUM(total_revenue) AS total_revenue, 
       COUNT(unique_part_count) AS total_unique_parts, 
       CASE WHEN SUM(total_revenue) IS NULL THEN 'No Revenue' ELSE 'Revenue Exists' END AS revenue_status
FROM FinalResults
GROUP BY r_name, supplier_count
HAVING COUNT(DISTINCT revenue_category) > 1
ORDER BY SUM(total_revenue) DESC NULLS LAST;
