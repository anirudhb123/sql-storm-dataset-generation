WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey = 0
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
order_stats AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_tax) AS total_tax,
        SUM(l.l_discount) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(os.total_orders, 0) AS total_orders,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    COALESCE(os.total_tax, 0) AS total_tax,
    COALESCE(os.total_discount, 0) AS total_discount,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Orders'
        WHEN os.total_revenue > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_classification,
    CONCAT('Region ', r.r_name, ' (Depth: ', nh.depth, ')') AS region_info
FROM customer c
LEFT JOIN order_stats os ON c.c_custkey = os.o_custkey
LEFT JOIN region r ON c.c_nationkey = r.r_regionkey
LEFT JOIN nation_hierarchy nh ON r.r_regionkey = nh.n_regionkey
WHERE c.c_acctbal IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 100;
