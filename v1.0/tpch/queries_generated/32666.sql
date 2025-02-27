WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT c.c_custkey) AS total_customers, 
           SUM(c.c_acctbal) AS total_account_balance
    FROM customer c
    LEFT JOIN nation_hierarchy nh ON c.c_nationkey = nh.n_nationkey
    GROUP BY c.c_nationkey
),
order_totals AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
supplier_performance AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_suppkey
),
ranked_suppliers AS (
    SELECT sp.ps_suppkey, sp.total_revenue,
           RANK() OVER (ORDER BY sp.total_revenue DESC) AS revenue_rank
    FROM supplier_performance sp
),
final_report AS (
    SELECT nh.n_name AS nation_name, cs.total_customers, 
           cs.total_account_balance, rs.total_revenue, rs.revenue_rank
    FROM customer_summary cs
    JOIN nation n ON cs.c_nationkey = n.n_nationkey
    LEFT JOIN ranked_suppliers rs ON rs.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps 
                                                       WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l 
                                                       JOIN orders o ON l.l_orderkey = o.o_orderkey 
                                                       WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c 
                                                       WHERE c.c_nationkey = n.n_nationkey))
                                                       ORDER BY ps.ps_supplycost DESC LIMIT 1)
    WHERE cs.total_account_balance IS NOT NULL
)
SELECT fr.nation_name, fr.total_customers, fr.total_account_balance, 
       COALESCE(fr.total_revenue, 0) AS revenue_from_suppliers,
       CASE WHEN fr.revenue_rank IS NOT NULL THEN 'Ranked' ELSE 'Unranked' END AS supplier_ranking
FROM final_report fr
ORDER BY fr.total_account_balance DESC, fr.nation_name;
