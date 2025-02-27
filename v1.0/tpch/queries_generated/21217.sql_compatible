
WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'EUROPE')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
order_summaries AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_custkey
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, os.total_revenue
    FROM customer c
    JOIN order_summaries os ON c.c_custkey = os.o_custkey
    WHERE os.revenue_rank <= 10
)
SELECT DISTINCT np.n_name, ps.part_count,
       CASE WHEN ps.part_count IS NULL THEN 'No parts' ELSE 'Parts available' END AS availability,
       COALESCE(ts.total_revenue, 0) AS customer_revenue
FROM nation_hierarchy np
LEFT JOIN supplier_stats ps ON np.n_nationkey = ps.s_suppkey
LEFT JOIN top_customers ts ON np.n_nationkey = ts.c_custkey
WHERE np.level > 0
  AND (ts.total_revenue IS NOT NULL OR np.n_name LIKE '%land%')
ORDER BY np.n_name, customer_revenue DESC
LIMIT 30;
