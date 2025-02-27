WITH RECURSIVE order_ranked AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
region_stats AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(COALESCE(o.o_totalprice, 0)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    rs.customer_count,
    rs.total_sales,
    ss.total_available,
    ss.avg_supply_cost,
    (SELECT COUNT(*) FROM order_ranked WHERE order_date = CURRENT_DATE) AS orders_today,
    (SELECT COUNT(DISTINCT customer_orders.c_custkey) FROM customer_orders WHERE total_spent > 1000) AS high_value_customers
FROM region_stats rs
JOIN supplier_summary ss ON rs.customer_count > 0
ORDER BY rs.total_sales DESC
LIMIT 10;
