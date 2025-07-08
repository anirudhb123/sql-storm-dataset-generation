WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        n.n_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
    ORDER BY order_count DESC
    LIMIT 5
)
SELECT 
    r.r_name AS region,
    SUM(os.total_revenue) AS total_revenue,
    MAX(os.customer_count) AS max_customers_per_order,
    COUNT(DISTINCT os.o_orderkey) AS total_orders
FROM OrderSummary os
JOIN TopRegions tr ON tr.region_name IN (
    SELECT n.n_name 
    FROM nation n 
    JOIN customer c ON n.n_nationkey = c.c_nationkey 
    JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE o.o_orderkey = os.o_orderkey
)
JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey FROM nation n WHERE n.n_name = tr.region_name
)
GROUP BY r.r_name
ORDER BY total_revenue DESC;