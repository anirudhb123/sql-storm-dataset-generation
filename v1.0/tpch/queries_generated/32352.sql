WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),
avg_price AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS average_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
total_orders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
detailed_orders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate,
           o.o_totalprice, l.l_linenumber, l.l_discount, l.l_returnflag,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, tc.total_spent,
           RANK() OVER (ORDER BY tc.total_spent DESC) AS customer_rank
    FROM customer c
    JOIN total_orders tc ON c.c_custkey = tc.o_custkey
    WHERE tc.total_spent > (SELECT AVG(total_spent) FROM total_orders)
),
final_report AS (
    SELECT r.r_name AS region, n.n_name AS nation, 
           s.s_name AS supplier_name, 
           p.p_name AS part_name, 
           ap.average_cost, 
           SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           MAX(coalesce(ord.o_orderdate, '1970-01-01')) AS last_order_date
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem lo ON p.p_partkey = lo.l_partkey
    LEFT JOIN detailed_orders ord ON lo.l_orderkey = ord.o_orderkey
    JOIN avg_price ap ON p.p_partkey = ap.ps_partkey
    GROUP BY r.r_name, n.n_name, s.s_name, p.p_name, ap.average_cost
)
SELECT f.region, f.nation, f.supplier_name, f.part_name, f.average_cost, 
       f.revenue, f.customer_count, 
       sh.hierarchy_level AS supplier_hierarchy_level
FROM final_report f
JOIN supplier_hierarchy sh ON f.supplier_name LIKE '%' || sh.s_name || '%'
ORDER BY f.revenue DESC, f.customer_count DESC;
