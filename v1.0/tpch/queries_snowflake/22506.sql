WITH RegionOrders AS (
    SELECT 
        r.r_regionkey, 
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
),
RankedRevenue AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        r.total_orders,
        r.total_revenue,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM RegionOrders r
),
TopRegions AS (
    SELECT 
        rr.r_regionkey,
        rr.r_name,
        rr.total_orders,
        rr.total_revenue,
        rr.revenue_rank
    FROM RankedRevenue rr
    WHERE rr.revenue_rank <= 5
)
SELECT 
    tr.r_regionkey,
    tr.r_name,
    COALESCE(tr.total_orders, 0) AS total_orders,
    COALESCE(tr.total_revenue, 0) AS total_revenue,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_nationkey IN (SELECT n.n_nationkey 
                              FROM nation n 
                              WHERE n.n_regionkey = tr.r_regionkey)) AS customer_count,
    (SELECT ROUND(AVG(l.l_quantity), 2) 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey 
                            FROM orders o 
                            WHERE o.o_orderstatus = 'F')) AS avg_line_quantity
FROM TopRegions tr
FULL OUTER JOIN (SELECT DISTINCT r.r_regionkey 
                 FROM region r 
                 WHERE r.r_comment IS NOT NULL) r2 ON tr.r_regionkey = r2.r_regionkey
WHERE (tr.total_orders > (SELECT AVG(total_orders) FROM TopRegions) OR tr.total_revenue IS NULL)
      AND (tr.total_revenue < (SELECT MAX(total_revenue) FROM TopRegions) 
           OR tr.total_orders IS NULL)
ORDER BY tr.r_regionkey ASC, tr.r_name DESC;
