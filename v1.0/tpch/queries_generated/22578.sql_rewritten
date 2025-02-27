WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
SelectedSuppliers AS (
    SELECT s.*
    FROM RankedSuppliers s
    WHERE s.rn = 1
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > 0
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
),
SupplierOrders AS (
    SELECT ss.s_suppkey, SUM(os.revenue) AS total_revenue
    FROM SelectedSuppliers ss
    JOIN partsupp ps ON ss.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN OrderStats os ON l.l_orderkey = os.o_orderkey
    GROUP BY ss.s_suppkey
),
RegionRevenue AS (
    SELECT r.r_regionkey, SUM(so.total_revenue) AS region_revenue
    FROM TopRegions r
    LEFT JOIN SupplierOrders so ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = so.s_suppkey) 
    GROUP BY r.r_regionkey
)
SELECT r.r_name, COALESCE(rr.region_revenue, 0) AS total_region_revenue
FROM TopRegions r
LEFT JOIN RegionRevenue rr ON r.r_regionkey = rr.r_regionkey
ORDER BY total_region_revenue DESC
LIMIT 10;