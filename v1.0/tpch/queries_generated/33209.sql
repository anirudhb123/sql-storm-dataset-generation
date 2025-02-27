WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer_hierarchy ch
    JOIN orders o ON ch.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    WHERE ch.level < 5 AND c.c_name LIKE 'A%'
),
product_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey, p.p_name
),
supplier_products AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS product_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    ch.c_name,
    SUM(ps.product_count) AS total_products,
    SUM(ps.product_count) FILTER (WHERE ps.product_count > 0) AS active_suppliers,
    COALESCE(SUM(ps.product_count) / NULLIF(SUM(ps.product_count) FILTER (WHERE ps.product_count > 0), 0), 1, 0) AS products_per_supplier,
    pm.p_name,
    pm.total_revenue,
    pm.order_count,
    RANK() OVER (PARTITION BY ch.level ORDER BY pm.total_revenue DESC) AS revenue_rank
FROM customer_hierarchy ch
JOIN supplier_products ps ON ch.c_custkey = ps.s_suppkey
JOIN product_summary pm ON ps.product_count = pm.total_revenue
GROUP BY ch.c_name, pm.p_name, pm.total_revenue, pm.order_count, ch.level
HAVING COUNT(DISTINCT ps.s_suppkey) > 1
ORDER BY ch.level, total_products DESC, revenue_rank;
