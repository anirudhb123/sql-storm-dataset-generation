WITH OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        o.o_orderdate,
        c.c_mktsegment,
        n.n_name AS nation_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_mktsegment, n.n_name
),
RankedOrders AS (
    SELECT 
        ot.o_orderkey,
        ot.total_amount,
        ot.o_orderdate,
        ot.c_mktsegment,
        RANK() OVER (PARTITION BY ot.c_mktsegment ORDER BY ot.total_amount DESC) AS rank
    FROM OrderTotals ot
)
SELECT 
    r.nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(ro.total_amount) AS avg_order_value
FROM RankedOrders ro
JOIN customer c ON ro.o_orderkey = c.c_custkey 
JOIN supplier s ON c.c_nationkey = s.s_nationkey 
JOIN nation n ON s.s_nationkey = n.n_nationkey 
WHERE ro.rank <= 10 
GROUP BY r.nation_name
ORDER BY order_count DESC, avg_order_value DESC;
