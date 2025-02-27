WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerRegion AS (
    SELECT c.c_custkey, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
RankedOrders AS (
    SELECT od.o_orderkey, od.total_order_value, cr.n_regionkey,
           RANK() OVER (PARTITION BY cr.n_regionkey ORDER BY od.total_order_value DESC) AS order_rank
    FROM OrderDetails od
    JOIN CustomerRegion cr ON od.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = cr.c_custkey)
)
SELECT r.r_name, SUM(sc.total_supply_cost) AS total_supply_cost_by_region,
       COUNT(DISTINCT ro.o_orderkey) AS order_count, 
       AVG(ro.total_order_value) AS avg_order_value
FROM RankedOrders ro
JOIN region r ON ro.n_regionkey = r.r_regionkey
JOIN SupplierCost sc ON ro.o_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_suppkey = sc.s_suppkey)
WHERE ro.order_rank <= 10
GROUP BY r.r_name
ORDER BY total_supply_cost_by_region DESC, order_count DESC;
