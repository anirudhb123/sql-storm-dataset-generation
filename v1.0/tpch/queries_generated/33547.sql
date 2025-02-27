WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name,
           SUM(COALESCE(ps.ps_availqty, 0)) AS total_availability,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderPrices AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
),
RankedOrders AS (
    SELECT op.o_custkey, op.total_order_price,
           RANK() OVER (PARTITION BY op.o_custkey ORDER BY op.total_order_price DESC) AS order_rank
    FROM OrderPrices op
)
SELECT ns.n_name,
       MIN(sh.level) AS min_level,
       MAX(r.total_order_price) AS max_total_price,
       AVG(CASE WHEN r.order_rank = 1 THEN r.total_order_price ELSE NULL END) AS avg_highest_order_price
FROM NationSummary ns
LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN RankedOrders r ON ns.n_nationkey = r.o_custkey
GROUP BY ns.n_name
HAVING COUNT(ns.supplier_count) > 1
ORDER BY max_total_price DESC, min_level ASC
LIMIT 10;
