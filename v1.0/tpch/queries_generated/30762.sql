WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level FROM region
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region_hierarchy rh
    JOIN nation n ON n.n_regionkey = rh.r_regionkey
    JOIN supplier s ON s.s_nationkey = n.n_nationkey
    WHERE NOT EXISTS (
        SELECT 1 
        FROM supplier s2 
        WHERE s2.s_nationkey = n.n_nationkey 
        AND s2.s_acctbal > s.s_acctbal
    )
), 
order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), 
supplier_quality AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_availqty) > 100
), 
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY CASE WHEN o.o_totalprice > 1000 THEN 'high' ELSE 'low' END ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
final_analysis AS (
    SELECT rh.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           AVG(ot.total) AS avg_order_value,
           MAX(sq.total_supply_cost) AS max_supply_cost,
           SUM(CASE WHEN ro.order_rank = 1 THEN 1 ELSE 0 END) AS high_value_orders
    FROM region_hierarchy rh
    LEFT JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rh.r_regionkey)
    LEFT JOIN order_totals ot ON ot.o_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_shipdate >= '2023-01-01')
    LEFT JOIN supplier_quality sq ON sq.s_suppkey = s.s_suppkey
    LEFT JOIN ranked_orders ro ON ro.o_orderkey = ot.o_orderkey
    GROUP BY rh.r_name
)
SELECT r_name, order_count, avg_order_value, max_supply_cost, high_value_orders
FROM final_analysis
WHERE (order_count > 10 OR max_supply_cost IS NOT NULL)
ORDER BY avg_order_value DESC, high_value_orders DESC;
