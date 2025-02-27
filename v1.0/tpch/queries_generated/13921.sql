WITH TotalRevenue AS (
    SELECT SUM(l_extendedprice * (1 - l_discount)) AS revenue
    FROM lineitem
    WHERE l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
)
SELECT r.r_name, SUM(tr.revenue) AS total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN (
    SELECT o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY o_custkey
) tr ON tr.o_custkey = customer.c_custkey
GROUP BY r.r_name
ORDER BY total_revenue DESC;
