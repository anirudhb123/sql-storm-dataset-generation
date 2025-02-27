WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_nombre,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
AggregateLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.c_custkey,
        ro.o_orderdate,
        al.total_revenue,
        al.item_count
    FROM RankedOrders ro
    JOIN AggregateLineItems al ON ro.o_orderkey = al.l_orderkey
    WHERE ro.order_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.c_custkey,
    t.o_orderdate,
    t.total_revenue,
    t.item_count,
    r.r_name AS region_name
FROM TopOrders t
JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = t.c_custkey)
JOIN region r ON n.n_regionkey = r.r_regionkey
ORDER BY t.total_revenue DESC, t.o_orderdate DESC 
LIMIT 5;
