WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus,
        r.r_name AS region_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY o.o_orderkey, o.o_orderstatus, r.r_name
),
RankedOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_revenue,
        od.o_orderstatus,
        od.region_name,
        RANK() OVER (PARTITION BY od.region_name ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM OrderDetails od
)
SELECT 
    ch.c_nationkey,
    ch.c_name,
    ro.total_revenue,
    ro.o_orderstatus,
    ro.region_name,
    CASE 
        WHEN ro.o_orderstatus = 'O' THEN 'Open'
        WHEN ro.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Unknown' 
    END AS order_status_description
FROM CustomerHierarchy ch
JOIN RankedOrders ro ON ch.c_custkey = ro.o_orderkey
WHERE ro.revenue_rank <= 10 
AND (ro.total_revenue IS NOT NULL OR ro.total_revenue > 5000)
ORDER BY ch.c_nationkey, ro.total_revenue DESC;
