WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PriorityOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'P')
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
AverageRevenue AS (
    SELECT AVG(total_revenue) AS avg_rev
    FROM LineItemSummary
)
SELECT ph.s_name AS supplier_name, po.o_orderdate, los.total_revenue,
       CASE
           WHEN los.total_revenue > (SELECT avg_rev FROM AverageRevenue) THEN 'High Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM SupplierHierarchy sh
JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN PriorityOrders po ON l.l_orderkey = po.o_orderkey
JOIN LineItemSummary los ON l.l_orderkey = los.l_orderkey
WHERE po.rn <= 5 AND l.l_returnflag = 'N'
ORDER BY sh.level, los.total_revenue DESC;
