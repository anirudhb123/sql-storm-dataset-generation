WITH RankedNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(rn.supplier_count) AS total_suppliers
    FROM region r
    JOIN (
        SELECT n.n_regionkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        GROUP BY n.n_regionkey
    ) AS rn ON r.r_regionkey = rn.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY total_suppliers DESC
    LIMIT 5
),
FinalStats AS (
    SELECT tp.r_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN TopRegions tp ON tp.logged_nations = o.o_custkey
    GROUP BY tp.r_name
)
SELECT r.r_name,
       COALESCE(SUM(fs.total_revenue), 0) AS total_revenue,
       COALESCE(SUM(fs.order_count), 0) AS total_orders
FROM TopRegions r
LEFT JOIN FinalStats fs ON r.r_name = fs.r_name
GROUP BY r.r_name
ORDER BY total_revenue DESC;
