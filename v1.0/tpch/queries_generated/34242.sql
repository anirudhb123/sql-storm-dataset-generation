WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL
    UNION ALL
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_acctbal < c.c_acctbal
    WHERE ch.level < 10
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost,
           AVG(ps.ps_availqty) AS avg_avail_qty, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 1000
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT ch.c_name AS customer_name,
       COALESCE(rs.r_name, 'Unknown') AS region_name,
       ss.s_name AS supplier_name,
       ss.total_supplycost,
       ss.avg_avail_qty,
       DENSE_RANK() OVER (PARTITION BY ch.level ORDER BY ch.c_acctbal DESC) AS rank_within_level
FROM CustomerHierarchy ch
LEFT JOIN RegionSummary rs ON ch.c_custkey % 10 = rs.nation_count % 10
LEFT JOIN SupplierStats ss ON ch.c_custkey % 5 = ss.part_count % 5
WHERE (ss.total_supplycost IS NOT NULL OR ch.c_acctbal > 500)
  AND ch.level < 5
ORDER BY ch.c_name, ss.total_supplycost DESC;
