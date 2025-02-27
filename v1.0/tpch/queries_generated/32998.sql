WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT MIN(r_regionkey) FROM region)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_nationkey
),
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (
        SELECT AVG(total_supply_cost)
        FROM (
            SELECT SUM(ps_supplycost * ps_availqty) AS total_supply_cost
            FROM partsupp ps
            GROUP BY ps.ps_suppkey
        ) AS avg_costs
    )
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
    GROUP BY o.o_orderkey
),
revenue_by_region AS (
    SELECT n.n_name, SUM(os.total_revenue) AS region_revenue
    FROM order_summary os
    JOIN customer c ON os.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
final_report AS (
    SELECT n.n_name, r.region_revenue, s.s_name, ts.total_supply_cost
    FROM revenue_by_region r
    JOIN nation n ON r.n_name = n.n_name
    LEFT JOIN top_suppliers ts ON ts.s_suppkey = (SELECT TOP 1 s_suppkey FROM supplier WHERE s_nationkey = n.n_nationkey ORDER BY ts.total_supply_cost DESC)
)
SELECT fr.n_name, fr.region_revenue, fr.s_name, fr.total_supply_cost
FROM final_report fr
WHERE fr.region_revenue IS NOT NULL
ORDER BY fr.region_revenue DESC, fr.total_supply_cost DESC;
