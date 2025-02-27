WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           c.c_name,
           c.c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT ro.o_orderkey,
           ro.o_orderdate,
           ro.o_totalprice,
           ro.c_name,
           ro.c_nationkey
    FROM RankedOrders ro
    WHERE ro.order_rank <= 5
),
OrderDetails AS (
    SELECT lo.l_orderkey,
           SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS net_revenue,
           COUNT(DISTINCT lo.l_partkey) AS unique_parts
    FROM lineitem lo
    JOIN TopOrders to ON lo.l_orderkey = to.o_orderkey
    GROUP BY lo.l_orderkey
)
SELECT to.o_orderkey,
       to.o_orderdate,
       to.o_totalprice,
       to.c_name,
       r.r_name AS region,
       od.net_revenue,
       od.unique_parts
FROM TopOrders to
JOIN customer c ON to.c_nationkey = c.c_nationkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN OrderDetails od ON to.o_orderkey = od.l_orderkey
ORDER BY od.net_revenue DESC, to.o_orderdate DESC;
