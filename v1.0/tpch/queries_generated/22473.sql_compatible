
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 
           CAST(s_name AS VARCHAR(255)) AS supplier_chain,
           1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%land%')
    
    UNION ALL
    
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, 
           CONCAT(sh.supplier_chain, ' -> ', sp.s_name),
           sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_name IS NOT NULL
),
PartStats AS (
    SELECT p.p_partkey, 
           COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderStats AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           MAX(l.l_shipdate) AS latest_shipping_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY o.o_orderkey
),
RegionRevenue AS (
    SELECT r.r_regionkey, 
           SUM(os.total_revenue) AS region_total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY r.r_regionkey
)
SELECT rh.supplier_chain,
       ps.p_partkey, 
       ps.total_suppliers, 
       ps.avg_supplycost,
       COALESCE(rr.region_total_revenue, 0) AS region_total_revenue,
       ROW_NUMBER() OVER (PARTITION BY rh.supplier_chain ORDER BY ps.avg_supplycost DESC) AS rank_within_chain
FROM SupplierHierarchy rh
JOIN PartStats ps ON TRUE
LEFT JOIN RegionRevenue rr ON rr.region_total_revenue > 100000
WHERE (ps.avg_supplycost IS NULL OR ps.avg_supplycost < 50.00)
  AND EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = rh.s_nationkey AND n.n_comment IS NOT NULL)
ORDER BY rh.level, ps.total_suppliers DESC, region_total_revenue DESC;
