WITH RECURSIVE supplier_tree AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000  -- Start with suppliers with a specific account balance

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, st.level + 1
    FROM supplier s
    JOIN supplier_tree st ON s.s_nationkey = st.s_nationkey
    WHERE s.s_acctbal > 500  -- Recursively find suppliers in the same nation
),
order_summary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
customer_with_sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(os.total_sales, 0) AS total_sales,
        os.order_count
    FROM customer c
    LEFT JOIN order_summary os ON c.c_custkey = os.o_custkey
),
ranked_customers AS (
    SELECT 
        cws.*,
        RANK() OVER (ORDER BY cws.total_sales DESC) AS sales_rank
    FROM customer_with_sales cws
)
SELECT 
    rt.s_name AS supplier_name,
    n.n_name AS nation_name,
    rc.c_name AS customer_name,
    rc.total_sales,
    rc.order_count,
    rt.level AS supplier_level
FROM ranked_customers rc
JOIN nation n ON rc.c_nationkey = n.n_nationkey
JOIN supplier_tree rt ON rc.total_sales > 0 AND rt.level < 3  -- Suppliers with total sales above zero
WHERE rc.total_sales IS NOT NULL
ORDER BY rt.s_name, rc.total_sales DESC;
