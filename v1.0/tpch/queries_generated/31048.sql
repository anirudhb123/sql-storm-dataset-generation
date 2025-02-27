WITH RECURSIVE nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN nation_supplier ns ON ns.n_nationkey = n.n_nationkey
    WHERE s.s_acctbal > ns.s_acctbal
),
part_analysis AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
order_details AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2021-01-01' AND l.l_shipdate < '2022-01-01'
    GROUP BY o.o_orderkey
),
ranked_orders AS (
    SELECT od.o_orderkey, od.revenue,
           RANK() OVER (ORDER BY od.revenue DESC) AS revenue_rank
    FROM order_details od
),
final_output AS (
    SELECT ns.n_name, ps.total_supply_cost, ro.revenue
    FROM nation_supplier ns
    FULL OUTER JOIN part_analysis ps ON ns.s_suppkey = ps.p_partkey
    FULL OUTER JOIN ranked_orders ro ON ro.o_orderkey = ps.p_partkey
)
SELECT n_name,
       COALESCE(total_supply_cost, 0) AS total_supply_cost,
       COALESCE(revenue, 0) AS revenue,
       CASE 
           WHEN total_supply_cost IS NULL OR revenue IS NULL THEN 'NA'
           ELSE 'Valid Data'
       END AS data_status
FROM final_output
ORDER BY n_name;
