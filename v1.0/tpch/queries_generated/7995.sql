WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS market_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        c.c_mktsegment, 
        SUM(revenue) AS total_revenue
    FROM RankedOrders ro
    JOIN customer c ON ro.o_orderkey = o.o_orderkey
    WHERE ro.market_rank <= 5
    GROUP BY c.c_mktsegment
)
SELECT 
    r.r_name AS region,
    ts.c_mktsegment,
    ts.total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN TopSegments ts ON ts.c_mktsegment = c.c_mktsegment
ORDER BY total_revenue DESC;
