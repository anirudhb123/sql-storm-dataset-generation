WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, SUM(si.total_supply_cost) AS nation_supply_cost
    FROM nation n
    JOIN SupplierInfo si ON n.n_nationkey = si.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ns.n_name, COUNT(DISTINCT co.c_custkey) AS customer_count, SUM(ns.nation_supply_cost) AS total_supply_cost, AVG(co.total_order_value) AS average_order_value
FROM NationSummary ns
JOIN CustomerOrders co ON ns.n_nationkey = (SELECT nation.n_nationkey FROM nation WHERE nation.n_nationkey = co.c_custkey)
GROUP BY ns.n_name
ORDER BY total_supply_cost DESC, customer_count DESC
LIMIT 10;
