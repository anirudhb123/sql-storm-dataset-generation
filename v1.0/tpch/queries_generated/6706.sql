WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SelectedOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.o_orderpriority,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM RankedOrders ro
    JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus, ro.o_orderpriority
    HAVING total_quantity > 100
),
CustomerSegments AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT so.o_orderkey) AS order_count,
        SUM(so.total_revenue) AS segment_revenue
    FROM customer c
    JOIN SelectedOrders so ON c.c_custkey = so.o_orderkey
    GROUP BY c.c_mktsegment
)
SELECT 
    cs.c_mktsegment,
    cs.order_count,
    cs.segment_revenue,
    RANK() OVER (ORDER BY cs.segment_revenue DESC) AS segment_rank
FROM CustomerSegments cs
WHERE cs.segment_revenue > 10000
ORDER BY cs.segment_rank;
