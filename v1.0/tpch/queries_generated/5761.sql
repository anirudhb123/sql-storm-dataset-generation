WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_mktsegment, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSegments AS (
    SELECT c_mktsegment, SUM(total_revenue) AS segment_revenue
    FROM RankedOrders
    GROUP BY c_mktsegment
    ORDER BY segment_revenue DESC
    LIMIT 5
)
SELECT t.c_mktsegment, TO_CHAR(t.total_revenue, 'FM$999,999,999.00') AS formatted_revenue
FROM (
    SELECT ro.c_mktsegment, SUM(ro.total_revenue) AS total_revenue
    FROM RankedOrders ro
    JOIN TopSegments ts ON ro.c_mktsegment = ts.c_mktsegment
    GROUP BY ro.c_mktsegment
) AS t
ORDER BY t.total_revenue DESC;
