WITH SupplierSummary AS (
    SELECT s.n_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.n_nationkey
), CustomerSummary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
), SalesData AS (
    SELECT ns.n_name, ns.r_name, COALESCE(ss.total_cost, 0) AS total_supply_cost, COALESCE(cs.total_orders, 0) AS order_count, COALESCE(cs.total_revenue, 0) AS total_revenue
    FROM nation ns
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    LEFT JOIN SupplierSummary ss ON ns.n_nationkey = ss.n_nationkey
    LEFT JOIN CustomerSummary cs ON ns.n_nationkey = cs.c_nationkey
)
SELECT r.r_name, SUM(sd.total_supply_cost) AS total_supply_cost, SUM(sd.order_count) AS total_orders, SUM(sd.total_revenue) AS total_revenue
FROM SalesData sd
JOIN region r ON sd.r_name = r.r_name
GROUP BY r.r_name
ORDER BY total_supply_cost DESC, total_revenue DESC;
