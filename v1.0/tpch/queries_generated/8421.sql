WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
), OrderRank AS (
    SELECT o.*, RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.total_revenue DESC) AS revenue_rank
    FROM RankedOrders o
)
SELECT r.r_name, 
       SUM(o.total_revenue) AS region_revenue,
       COUNT(*) AS number_of_orders
FROM OrderRank o
JOIN nation n ON o.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE o.revenue_rank <= 5
GROUP BY r.r_name
ORDER BY region_revenue DESC;
