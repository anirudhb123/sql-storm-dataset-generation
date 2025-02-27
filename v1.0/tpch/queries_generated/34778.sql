WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
high_value_orders AS (
    SELECT os.o_orderkey, os.total_revenue, ROW_NUMBER() OVER (PARTITION BY os.total_revenue ORDER BY os.total_revenue DESC) AS rnk
    FROM order_summary os
    WHERE os.total_revenue > 10000
),
supply_info AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost, p.p_brand
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
final_selection AS (
    SELECT s.s_name, s.s_nationkey, COALESCE(hi.total_revenue, 0) AS order_revenue, si.total_supply_cost
    FROM supplier_hierarchy s
    LEFT JOIN high_value_orders hi ON s.s_suppkey = hi.o_orderkey
    JOIN supply_info si ON s.s_nationkey = si.p_partkey
)
SELECT f.s_name, f.order_revenue, f.total_supply_cost,
       CASE 
           WHEN f.order_revenue IS NULL THEN 'No Orders'
           WHEN f.total_supply_cost > f.order_revenue THEN 'Cost Over Revenue'
           ELSE 'Profit'
       END AS profitability_status,
       RANK() OVER (ORDER BY f.order_revenue DESC) AS revenue_rank
FROM final_selection f
WHERE f.total_supply_cost IS NOT NULL
ORDER BY f.revenue_rank DESC;
