WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation_hierarchy nh
    JOIN nation n ON nh.n_regionkey = n.n_nationkey
),
ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
summary_orders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
top_customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        CASE 
            WHEN SUM(o.o_totalprice) > 50000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_status
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    th.customer_status,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN AVG(l.l_quantity) > 10 THEN 'High'
        ELSE 'Low'
    END AS quantity_status,
    COALESCE(n.n_name, 'Unknown') AS nation_name
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN ranked_suppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.rk = 1
LEFT JOIN top_customers th ON o.o_custkey = th.c_custkey
LEFT JOIN nation_hierarchy n ON th.c_custkey = n.n_nationkey
WHERE p.p_retailprice IS NOT NULL
GROUP BY p.p_name, th.customer_status, n.n_name
HAVING SUM(l.l_extendedprice) > 10000
ORDER BY revenue DESC
LIMIT 10;
