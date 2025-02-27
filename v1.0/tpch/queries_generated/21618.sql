WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, 
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
),
final_summary AS (
    SELECT n.n_name, COUNT(DISTINCT co.c_custkey) AS customer_count,
           SUM(co.total_spent) AS total_revenue,
           AVG(ps.total_supply_cost) AS avg_supply_cost,
           MAX(r.order_rank) AS max_order_rank
    FROM nation_hierarchy n
    JOIN customer_order_summary co ON n.n_nationkey = co.c_custkey
    JOIN part_supplier_info ps ON ps.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderstatus = 'O'
    )
    LEFT JOIN ranked_orders r ON r.o_custkey = co.c_custkey
    GROUP BY n.n_name
)
SELECT f.n_name, f.customer_count,
       CASE 
           WHEN f.total_revenue IS NULL THEN 'No Revenue'
           WHEN f.total_revenue < 10000 THEN 'Low Revenue'
           ELSE 'High Revenue'
       END AS revenue_category,
       f.avg_supply_cost,
       f.max_order_rank
FROM final_summary f
WHERE f.customer_count > 0
ORDER BY f.total_revenue DESC, f.n_name;
