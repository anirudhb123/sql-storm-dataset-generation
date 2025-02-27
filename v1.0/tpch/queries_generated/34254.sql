WITH RECURSIVE RegionHierarchy AS (
    SELECT r.r_regionkey, r.r_name, 1 AS level
    FROM region r
    WHERE r.r_name = 'ASIA'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, rh.level + 1
    FROM nation n
    JOIN RegionHierarchy rh ON n.n_regionkey = rh.r_regionkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS supply_count,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
           COUNT(DISTINCT l.l_partkey) AS items_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT od.o_orderkey, od.order_total
    FROM OrderDetails od
    WHERE od.order_total > (SELECT AVG(order_total) FROM OrderDetails)
),
SupplierOrders AS (
    SELECT ss.s_suppkey, ss.s_name, SUM(od.order_total) AS total_orders_value
    FROM SupplierStats ss
    JOIN lineitem l ON ss.s_suppkey = l.l_suppkey
    JOIN HighValueOrders ho ON l.l_orderkey = ho.o_orderkey
    GROUP BY ss.s_suppkey, ss.s_name
)
SELECT rh.r_name, so.s_name, so.total_orders_value
FROM RegionHierarchy rh
JOIN SupplierOrders so ON rh.r_regionkey = so.s_suppkey
ORDER BY so.total_orders_value DESC
LIMIT 10;
