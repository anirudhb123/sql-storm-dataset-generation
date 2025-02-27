WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_order_value) AS total_orders_value
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN order_summary os ON c.c_custkey = os.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name AS region, ns.n_name AS nation, ns.total_orders_value, ss.total_supply_cost
FROM region r
JOIN nation_summary ns ON r.r_regionkey = (SELECT n.r_regionkey FROM nation n WHERE n.n_nationkey = ns.n_nationkey)
JOIN supplier_summary ss ON ns.n_nationkey = ss.s_nationkey
WHERE ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_summary)
ORDER BY region, nation;
