WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS item_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
FinalReport AS (
    SELECT rh.s_name, ns.n_name, od.item_count, od.total_revenue, NULLIF(ns.total_supply_cost, 0) AS supply_cost,
           ROW_NUMBER() OVER (PARTITION BY ns.n_nationkey ORDER BY od.total_revenue DESC) AS rank_within_nation
    FROM OrderDetails od
    JOIN SupplierHierarchy rh ON od.o_orderkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = rh.s_suppkey)
    LEFT JOIN NationStats ns ON rh.s_nationkey = ns.n_nationkey
)
SELECT f.s_name, f.n_name, f.item_count, f.total_revenue, f.supply_cost, f.rank_within_nation
FROM FinalReport f
WHERE f.supply_cost IS NOT NULL
ORDER BY f.n_name, f.total_revenue DESC;
