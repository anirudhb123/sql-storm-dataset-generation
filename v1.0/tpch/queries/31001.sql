
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
PartSummary AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
CustomerRevenue AS (
    SELECT c.c_custkey, SUM(os.total_revenue) AS customer_revenue
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey
),
RegionStatistics AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(ps.total_available) AS total_parts,
           AVG(ps.avg_cost) AS avg_supply_cost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN PartSummary ps ON ps.p_partkey IN (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_suppkey IN (SELECT s_suppkey FROM SupplierHierarchy WHERE level = 1)
    )
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rs.r_name, rs.nation_count, rs.total_parts, rs.avg_supply_cost, cr.customer_revenue
FROM RegionStatistics rs
LEFT JOIN CustomerRevenue cr ON rs.r_regionkey = cr.c_custkey
WHERE cr.customer_revenue IS NOT NULL
ORDER BY rs.total_parts DESC, cr.customer_revenue DESC
LIMIT 100;
