WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_acctbal AS customer_balance,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
),
TopOrders AS (
    SELECT 
        ro.*,
        n.n_name AS nation_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM RankedOrders ro
    JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
    JOIN customer c ON ro.customer_name = c.c_name
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE ro.order_rank <= 10
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.customer_name, ro.customer_balance, n.n_name
)
SELECT 
    to.nation_name,
    COUNT(DISTINCT to.o_orderkey) AS number_of_orders,
    SUM(to.total_revenue) AS total_revenue,
    AVG(to.o_totalprice) AS average_order_value
FROM TopOrders to
GROUP BY to.nation_name
ORDER BY total_revenue DESC, number_of_orders DESC;
