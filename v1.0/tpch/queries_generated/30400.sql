WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
final_summary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        SUM(co.total_spent) AS total_sales,
        MAX(co.avg_order_value) AS highest_avg_order,
        MAX(co.total_orders) AS most_orders,
        MIN(co.total_orders) AS least_orders
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN customer_orders co ON c.c_custkey = co.c_custkey
    GROUP BY n.n_name
)

SELECT 
    fh.nation_name,
    fh.unique_customers,
    fh.total_sales,
    fh.highest_avg_order,
    fh.most_orders,
    CASE 
        WHEN fh.least_orders IS NULL THEN 'No orders'
        ELSE fh.least_orders
    END AS least_orders,
    sh.level AS supplier_level
FROM final_summary fh
JOIN supplier_hierarchy sh ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0 LIMIT 1)
WHERE fh.total_sales IS NOT NULL
ORDER BY fh.total_sales DESC, fh.nation_name;
