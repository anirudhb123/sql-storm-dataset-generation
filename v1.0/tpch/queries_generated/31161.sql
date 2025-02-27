WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE n.n_nationkey <> nh.n_nationkey
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_analysis AS (
    SELECT 
        l.l_orderkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
        COUNT(*) AS total_items,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    nh.n_name,
    ss.s_name,
    COALESCE(cs.total_order_value, 0) AS total_order_value,
    la.avg_price_after_discount,
    la.total_items,
    ss.total_parts,
    ss.total_supplycost,
    CASE 
        WHEN la.total_returns > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status
FROM nation_hierarchy nh
LEFT JOIN supplier_summary ss ON nh.n_nationkey = ss.s_suppkey
LEFT JOIN customer_order_summary cs ON nh.n_nationkey = cs.c_custkey
LEFT JOIN lineitem_analysis la ON cs.total_orders = la.total_items
WHERE ss.total_supplycost IS NOT NULL
ORDER BY nh.n_name, ss.s_name;
