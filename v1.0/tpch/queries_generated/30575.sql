WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (sh.level + 1) * 5000
),
PartKeywords AS (
    SELECT p.p_partkey, 
           COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, 
           c.c_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY o.o_orderkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
RankedOrders AS (
    SELECT r.row_num, ro.o_orderkey, ro.c_name, ro.total_revenue,
           RANK() OVER (PARTITION BY ro.c_name ORDER BY ro.total_revenue DESC) AS revenue_rank
    FROM RecentOrders ro
    CROSS JOIN (SELECT ROW_NUMBER() OVER () AS row_num FROM orders) r
)
SELECT ph.p_partkey, ph.supplier_count, ph.avg_supplycost, 
       COUNT(DISTINCT ro.o_orderkey) AS order_count,
       MAX(ro.total_revenue) AS max_revenue
FROM PartKeywords ph
LEFT JOIN RankedOrders ro ON ph.p_partkey IN (
    SELECT DISTINCT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE c.c_nationkey IN (
            SELECT n.n_nationkey
            FROM nation n
            JOIN region r ON n.n_regionkey = r.r_regionkey
            WHERE r.r_name LIKE 'A%'
        )
    )
)
GROUP BY ph.p_partkey, ph.supplier_count, ph.avg_supplycost
ORDER BY max_revenue DESC
LIMIT 10;
