WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), TopOrders AS (
    SELECT 
        ro.order_rank,
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.customer_name,
        ro.region_name
    FROM RankedOrders ro
    WHERE ro.order_rank <= 5
)
SELECT 
    to.region_name,
    COUNT(*) AS top_order_count,
    AVG(to.o_totalprice) AS average_price,
    SUM(to.o_totalprice) AS total_revenue
FROM TopOrders to
GROUP BY to.region_name
ORDER BY total_revenue DESC;
