WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey, RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
),
TopOrders AS (
    SELECT *
    FROM RankedOrders
    WHERE order_rank <= 5
),
OrderLineItems AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM lineitem lo
    JOIN TopOrders to ON lo.l_orderkey = to.o_orderkey
    GROUP BY lo.l_orderkey
),
NationRevenue AS (
    SELECT n.n_name, SUM(oli.total_revenue) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN TopOrders to ON c.c_custkey = to.o_custkey
    JOIN OrderLineItems oli ON to.o_orderkey = oli.l_orderkey
    GROUP BY n.n_name
)
SELECT nr.n_name, nr.total_revenue, CASE
    WHEN nr.total_revenue > 100000 THEN 'High Revenue'
    WHEN nr.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
    ELSE 'Low Revenue'
END AS revenue_category
FROM NationRevenue nr
ORDER BY nr.total_revenue DESC;
