WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name, 1 AS depth
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_nationkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name, nh.depth + 1
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN NationHierarchy nh ON n.n_nationkey = nh.n_nationkey
    WHERE nh.depth < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT os.o_orderkey, os.total_revenue, RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderSummary os
),
TopSuppliers AS (
    SELECT ss.s_suppkey, ss.s_name, ss.total_available_qty, ss.avg_supply_cost
    FROM SupplierStats ss
    WHERE ss.total_available_qty > 100 AND ss.avg_supply_cost < (
        SELECT AVG(avg_supply_cost) FROM SupplierStats
    )
)
SELECT nh.n_name AS nation_name,
       r.r_name AS region_name,
       ts.s_name AS supplier_name,
       ro.total_revenue,
       ro.revenue_rank,
       COALESCE(ts.total_available_qty, 0) AS supplier_available_qty,
       COALESCE(ts.avg_supply_cost, 0) AS supplier_avg_cost
FROM NationHierarchy nh
LEFT JOIN region r ON nh.r_regionkey = r.r_regionkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
)
JOIN RankedOrders ro ON ro.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_suppkey = ts.s_suppkey
)
ORDER BY nh.n_name, revenue_rank;
