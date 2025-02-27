WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 2
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_discount) AS total_discount,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice
),
SuspiciousOrders AS (
    SELECT os.o_orderkey, os.o_totalprice, os.total_discount
    FROM OrderSummary os
    WHERE os.total_discount > (os.o_totalprice * 0.2)
),
SupplierStats AS (
    SELECT sh.s_nationkey, AVG(sh.s_acctbal) AS avg_acctbal, MAX(sh.level) AS max_hierarchy
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
)
SELECT r.r_name,
       ss.avg_acctbal,
       COALESCE(SUM(so.o_totalprice), 0) AS total_suspicious_order_value,
       COUNT(DISTINCT so.o_orderkey) AS total_suspicious_orders,
       COUNT(DISTINCT sh.s_suppkey) AS total_suppliers
FROM TopRegions r
LEFT JOIN SupplierStats ss ON r.r_regionkey = ss.s_nationkey
LEFT JOIN SuspiciousOrders so ON ss.s_nationkey = so.o_orderkey
LEFT JOIN supplier sh ON sh.s_nationkey = ss.s_nationkey
GROUP BY r.r_name, ss.avg_acctbal
ORDER BY r.r_name;
