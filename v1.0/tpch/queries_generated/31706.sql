WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem)
),
supplier_stats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS supplied_parts, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
ranked_summary AS (
    SELECT cs.c_custkey, cs.total_spent, cs.order_count, 
           RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM customer_summary cs
)
SELECT n.n_name, 
       SUM(CASE WHEN ho.order_value IS NOT NULL THEN ho.order_value ELSE 0 END) AS total_order_value,
       COUNT(DISTINCT ho.o_orderkey) AS order_count,
       AVG(ss.avg_supplycost) AS average_supply_cost,
       COUNT(DISTINCT rs.c_custkey) AS customer_count,
       MAX(rs.spend_rank) AS max_rank
FROM nation n
LEFT JOIN high_value_orders ho ON n.n_nationkey = ho.o_orderkey
LEFT JOIN supplier_stats ss ON ss.supplied_parts > 10
LEFT JOIN ranked_summary rs ON rs.total_spent > 1000
GROUP BY n.n_name
ORDER BY total_order_value DESC, customer_count DESC;
