WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT n_regionkey FROM nation_hierarchy)
),
avg_part_cost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
eligible_orders AS (
    SELECT o.o_orderkey, os.total_revenue, os.total_revenue - COALESCE(AVG(p.avg_cost), 0) AS profit
    FROM order_summary os
    JOIN avg_part_cost p ON os.total_revenue > (SELECT AVG(total_revenue) FROM order_summary) 
    JOIN orders o ON os.o_orderkey = o.o_orderkey
)
SELECT r.r_name, 
       SUM(eo.profit) AS total_profit, 
       COUNT(DISTINCT eo.o_orderkey) AS order_count, 
       AVG(s.s_acctbal) AS supplier_avg_balance
FROM eligible_orders eo
JOIN supplier s ON eo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = s.s_suppkey)
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
HAVING SUM(eo.profit) > 0
ORDER BY total_profit DESC;
