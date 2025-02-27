WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT
        s.nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM supplier s
    GROUP BY s.nationkey
),
order_metrics AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderpriority,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_orderpriority
)
SELECT
    r.r_name AS region_name,
    nh.n_name AS nation_name,
    ss.total_suppliers,
    ss.total_acct_balance,
    COUNT(DISTINCT om.o_orderkey) AS total_orders,
    SUM(om.revenue) AS total_revenue,
    AVG(om.line_item_count) AS avg_items_per_order
FROM region r
LEFT JOIN nation_hierarchy nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN supplier_stats ss ON nh.n_nationkey = ss.nationkey
LEFT JOIN order_metrics om ON nh.n_nationkey = om.orderkey
WHERE r.r_name IS NOT NULL
  AND ss.total_acct_balance IS NOT NULL
GROUP BY r.r_name, nh.n_name, ss.total_suppliers, ss.total_acct_balance
HAVING SUM(om.revenue) > 10000
ORDER BY total_orders DESC, total_revenue DESC;
