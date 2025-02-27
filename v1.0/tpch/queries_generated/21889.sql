WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o 
    WHERE o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
null_example AS (
    SELECT 
        N.n_nationkey,
        COALESCE(NULLIF(MAX(c.c_acctbal), 0), 0) AS max_account_balance
    FROM nation N 
    LEFT JOIN customer c ON N.n_nationkey = c.c_nationkey
    GROUP BY N.n_nationkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN os.price_rank = 1 THEN os.o_totalprice ELSE 0 END) AS highest_order_total,
    SUM(ss.total_avail_qty) AS total_available_qty,
    SUM(os.revenue) AS total_revenue,
    SUM(n.max_account_balance) AS collective_balance
FROM ranked_orders os
JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey 
    FROM nation n
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey
    HAVING COUNT(c.c_custkey) > 0
    ORDER BY COUNT(c.c_custkey) DESC LIMIT 1)
LEFT JOIN order_summary os ON os.o_orderkey = os.o_orderkey
LEFT JOIN supplier_stats ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0
)
LEFT JOIN null_example n ON n.n_nationkey = r.r_regionkey
GROUP BY r.r_name
HAVING SUM(n.max_account_balance) IS NOT NULL AND COUNT(DISTINCT os.o_orderkey) > 0
ORDER BY total_orders DESC, highest_order_total DESC;
