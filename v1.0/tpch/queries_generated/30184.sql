WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_suppkey = sh.s_suppkey
    WHERE sp.s_acctbal < sh.s_acctbal
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 5000
),
LineitemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
AggregatedData AS (
    SELECT
        n.n_name AS nation_name,
        SUM(p.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(l.total_revenue) AS avg_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM partsupp p
    JOIN part pa ON p.ps_partkey = pa.p_partkey
    JOIN supplier s ON p.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM HighValueOrders o WHERE o.o_totalprice > 50000)
    GROUP BY n.n_name
),
FinalOutput AS (
    SELECT 
        ad.nation_name,
        ad.total_supply_cost,
        COALESCE(SH.level, 0) AS supplier_level,
        ad.avg_revenue,
        ad.order_count
    FROM AggregatedData ad
    LEFT JOIN SupplierHierarchy SH ON SH.s_acctbal < ad.total_supply_cost
)
SELECT 
    *, 
    CASE 
        WHEN avg_revenue IS NULL OR total_supply_cost < 10000 THEN 'Below Average'
        WHEN avg_revenue >= 10000 THEN 'Above Average'
        ELSE 'Average'
    END AS revenue_category
FROM FinalOutput
ORDER BY total_supply_cost DESC, avg_revenue DESC;
