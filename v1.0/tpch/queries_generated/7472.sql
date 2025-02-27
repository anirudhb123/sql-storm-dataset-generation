WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_revenue DESC
    LIMIT 5
)
SELECT 
    r.r_name,
    t.n_name,
    COUNT(DISTINCT t.n_nationkey) AS unique_nations,
    SUM(t.total_revenue) AS total_revenue,
    MAX(o.rank) AS max_order_rank
FROM region r
JOIN TopNations t ON r.r_regionkey = (
    SELECT n_r.n_regionkey 
    FROM nation n_r 
    WHERE n_r.n_nationkey = t.n_nationkey
)
JOIN RankedOrders o ON t.total_revenue > 1000000
GROUP BY r.r_name, t.n_name
ORDER BY total_revenue DESC;
