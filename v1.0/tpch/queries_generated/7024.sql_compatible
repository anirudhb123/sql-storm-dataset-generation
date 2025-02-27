
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopNOrders AS (
    SELECT 
        o_orderdate AS order_date,
        o_orderkey,
        total_revenue
    FROM RankedOrders
    WHERE revenue_rank <= 10
    ORDER BY o_orderdate, total_revenue DESC
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT lo.o_orderkey) AS order_count,
    SUM(lo.total_revenue) AS total_revenue
FROM TopNOrders lo
JOIN customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lo.o_orderkey)
JOIN supplier s ON s.s_nationkey = c.c_nationkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name, n.n_name, s.s_name
HAVING COUNT(DISTINCT lo.o_orderkey) > 5
ORDER BY total_revenue DESC;
