WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_acctbal, COUNT(s_suppkey) AS sup_count
    FROM supplier
    GROUP BY s_nationkey
),
order_summary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
)
SELECT r.r_name, nh.n_name, COALESCE(ss.avg_acctbal, 0) AS avg_acctbal, 
       COALESCE(ss.sup_count, 0) AS sup_count, os.total_revenue,
       CASE WHEN os.revenue_rank <= 3 THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_type
FROM region r
LEFT JOIN nation_hierarchy nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN supplier_stats ss ON nh.n_nationkey = ss.s_nationkey
LEFT JOIN order_summary os ON ss.s_nationkey = os.o_custkey
WHERE ss.avg_acctbal IS NOT NULL OR os.total_revenue IS NOT NULL
ORDER BY r.r_name, nh.level;
