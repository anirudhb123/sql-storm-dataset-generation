WITH recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, l.l_extendedprice, l.l_discount
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
region_totals AS (
    SELECT r.r_regionkey, r.r_name, SUM(ro.l_extendedprice * (1 - ro.l_discount)) AS total_revenue
    FROM recent_orders ro
    JOIN nation n ON ro.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
supplier_part_totals AS (
    SELECT ps.ps_partkey, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey
),
final_report AS (
    SELECT rt.r_name AS region_name, COUNT(DISTINCT ro.o_orderkey) AS total_orders,
           SUM(rt.total_revenue) AS region_revenue,
           SUM(sp.total_supply_cost) AS supplier_cost
    FROM region_totals rt
    LEFT JOIN recent_orders ro ON ro.n_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        JOIN region r ON n.n_regionkey = r.r_regionkey AND r.r_name = rt.r_name
    )
    LEFT JOIN supplier_part_totals sp ON sp.ps_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE ps.ps_availqty > 0
    )
    GROUP BY rt.r_name
)
SELECT region_name, total_orders, region_revenue, supplier_cost
FROM final_report
ORDER BY region_revenue DESC
LIMIT 10;
