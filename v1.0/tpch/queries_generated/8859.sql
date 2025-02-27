WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, c.c_nationkey
    FROM RankedOrders ro
    JOIN customer c ON ro.o_orderkey = c.c_custkey
    WHERE ro.order_rank <= 5
),
OrderDetails AS (
    SELECT to.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM TopOrders to
    JOIN lineitem li ON to.o_orderkey = li.l_orderkey
    GROUP BY to.o_orderkey
)
SELECT n.n_name, SUM(od.total_revenue) AS total_revenue_by_nation
FROM OrderDetails od
JOIN supplier s ON od.o_orderkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY total_revenue_by_nation DESC
LIMIT 10;
