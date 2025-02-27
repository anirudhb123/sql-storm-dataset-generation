WITH RegionalAvg AS (
    SELECT r.r_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
),
HighCostSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount BETWEEN 0.05 AND 0.1
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT od.o_orderkey, od.total_revenue,
           RANK() OVER (ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM OrderDetails od
)
SELECT r.r_name, COALESCE(hs.s_name, 'No Supplier') AS supplier_name,
       ra.avg_supplycost, ro.total_revenue, ro.revenue_rank
FROM RegionalAvg ra
LEFT JOIN HighCostSuppliers hs ON ra.avg_supplycost < (SELECT MAX(ps_supplycost) FROM partsupp)
JOIN RankedOrders ro ON ra.r_name = (
    SELECT n.r_name 
    FROM nation n 
    WHERE n.n_nationkey = (
        SELECT s.n_nationkey 
        FROM supplier s 
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        WHERE ps.ps_supplycost = ra.avg_supplycost
    )
)
WHERE ra.avg_supplycost IS NOT NULL
ORDER BY ra.r_name, ro.revenue_rank
LIMIT 10 OFFSET 5;
