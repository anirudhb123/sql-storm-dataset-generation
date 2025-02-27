WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_availqty) AS total_available_quantity, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name AS customer_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
),
combined AS (
    SELECT co.o_orderkey, co.o_orderdate, co.customer_name, ss.s_name AS supplier_name, ss.nation_name, ss.total_available_quantity, ss.total_supply_cost, co.total_revenue
    FROM order_summary co
    JOIN supplier_summary ss ON co.o_orderkey % 10 = ss.s_suppkey % 10
)
SELECT cs.o_orderkey, cs.o_orderdate, cs.customer_name, cs.supplier_name, cs.nation_name, cs.total_available_quantity, cs.total_supply_cost, cs.total_revenue,
       (cs.total_revenue - cs.total_supply_cost) AS profit_margin,
       RANK() OVER (PARTITION BY cs.nation_name ORDER BY cs.total_revenue DESC) AS revenue_rank
FROM combined cs
WHERE cs.total_available_quantity > 1000
ORDER BY cs.o_orderdate DESC, profit_margin DESC
LIMIT 50;
