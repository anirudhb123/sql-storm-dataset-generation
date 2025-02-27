WITH RankedRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
),
TopRegions AS (
    SELECT r_regionkey, r_name, total_revenue, RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM RankedRegions
)
SELECT tr.r_name, tr.total_revenue, COUNT(DISTINCT o.o_orderkey) AS order_count
FROM TopRegions tr
JOIN orders o ON tr.r_regionkey = (SELECT n.n_regionkey
                                    FROM nation n
                                    JOIN supplier s ON n.n_nationkey = s.s_nationkey
                                    WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps
                                                          JOIN part p ON ps.ps_partkey = p.p_partkey
                                                          WHERE p.p_brand = 'Brand#23'))
WHERE tr.revenue_rank <= 5
GROUP BY tr.r_name, tr.total_revenue
ORDER BY tr.total_revenue DESC;
