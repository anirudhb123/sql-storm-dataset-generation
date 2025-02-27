WITH RECURSIVE nation_order_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name

    UNION ALL

    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) + summary.total_orders AS total_orders,
        COALESCE(SUM(o.o_totalprice) + summary.total_revenue, summary.total_revenue) AS total_revenue
    FROM nation n
    JOIN nation_order_summary summary ON summary.n_nationkey = n.n_nationkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE summary.total_orders < 100
    GROUP BY n.n_nationkey, n.n_name, summary.total_orders, summary.total_revenue
),
ranked_orders AS (
    SELECT 
        n.n_name,
        summary.total_orders,
        summary.total_revenue,
        RANK() OVER (ORDER BY summary.total_revenue DESC) AS revenue_rank
    FROM nation_order_summary summary
    JOIN nation n ON summary.n_nationkey = n.n_nationkey
    WHERE summary.total_orders > 10
)
SELECT 
    r.n_name,
    r.total_orders,
    r.total_revenue,
    CASE 
        WHEN r.revenue_rank <= 5 THEN 'Top Performer'
        WHEN r.revenue_rank <= 10 THEN 'Moderate Performer'
        ELSE 'Lower Ranked'
    END AS performance_category
FROM ranked_orders r
ORDER BY r.total_revenue DESC
LIMIT 10;
