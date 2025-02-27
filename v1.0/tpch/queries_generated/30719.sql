WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'AMERICA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT s.s_nationkey, AVG(s.s_acctbal) AS avg_acctbal, COUNT(s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
regional_stats AS (
    SELECT r.r_name, SUM(ss.avg_acctbal) AS total_avg_acctbal, SUM(ss.supplier_count) AS total_suppliers
    FROM region r
    LEFT JOIN supplier_stats ss ON r.r_regionkey = ss.s_nationkey
    GROUP BY r.r_name
)
SELECT n.n_name, COALESCE(os.total_revenue, 0) AS total_revenue, 
       r.total_avg_acctbal, r.total_suppliers,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY COALESCE(os.total_revenue, 0) DESC) AS revenue_rank
FROM nation_hierarchy n
LEFT JOIN order_summary os ON n.n_nationkey = os.o_orderkey
JOIN regional_stats r ON n.n_regionkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = n.n_nationkey)
WHERE r.total_suppliers > 0
ORDER BY n.n_name ASC;
