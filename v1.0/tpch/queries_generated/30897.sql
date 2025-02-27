WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN top_customers tc ON o.o_custkey = tc.c_custkey
    JOIN customer c ON c.c_custkey = o.o_custkey
),
final_summary AS (
    SELECT c.c_name, 
           COALESCE(SUM(ls.total_revenue), 0) AS total_revenue,
           COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
           nh.level
    FROM top_customers c
    LEFT JOIN lineitem_summary ls ON ls.l_orderkey IN (SELECT o_orderkey FROM order_details WHERE rn = 1)
    LEFT JOIN supplier_summary ss ON ss.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part))
    JOIN nation_hierarchy nh ON c.c_nationkey = nh.n_nationkey
    GROUP BY c.c_name, nh.level
)
SELECT fs.c_name, fs.total_revenue, fs.total_supply_cost, r.r_name AS region
FROM final_summary fs
JOIN nation n ON fs.level = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE fs.total_revenue > 10000 AND fs.total_supply_cost IS NOT NULL
ORDER BY fs.total_revenue DESC, fs.total_supply_cost ASC;
