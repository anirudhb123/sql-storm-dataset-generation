WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), NationalSupply AS (
    SELECT n.n_name, SUM(rs.total_supply_cost) AS total_cost
    FROM nation n
    JOIN RankedSuppliers rs ON n.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
    GROUP BY n.n_name
), OrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ns.n_name,
       os.total_order_value,
       ns.total_cost,
       (os.total_order_value / nullif(ns.total_cost, 0)) AS order_to_supply_ratio
FROM NationalSupply ns
JOIN OrderSummary os ON ns.total_cost > 0
ORDER BY order_to_supply_ratio DESC
LIMIT 10;
