WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSegments AS (
    SELECT
        c.c_mktsegment,
        SUM(r.revenue) AS total_revenue
    FROM RankedOrders r
    JOIN customer c ON r.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1)
    WHERE r.revenue_rank <= 10
    GROUP BY c.c_mktsegment
)
SELECT 
    ts.c_mktsegment,
    ts.total_revenue,
    r.r_name AS region_name,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM TopSegments ts
JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_mktsegment = ts.c_mktsegment LIMIT 1)
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
GROUP BY ts.c_mktsegment, ts.total_revenue, r.r_name
ORDER BY ts.total_revenue DESC;