WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    GROUP BY o.o_custkey
), NationRegion AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT NRR.n_name, NRR.r_name, SS.s_name, SS.total_avail_qty, SS.total_supply_cost, OS.total_orders, OS.total_order_value
FROM NationRegion NRR
JOIN SupplierSummary SS ON NRR.total_suppliers > 10
JOIN OrderSummary OS ON OS.o_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_name = NRR.n_name
)
WHERE SS.total_supply_cost > 1000.00
ORDER BY NRR.r_name, SS.total_avail_qty DESC, OS.total_order_value DESC;
