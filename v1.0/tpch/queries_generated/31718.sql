WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY ps.ps_partkey
),
RegionAggregates AS (
    SELECT n.n_regionkey, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN customer c ON s.s_suppkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, ps.supplier_count, ps.avg_supplycost,
           RANK() OVER (PARTITION BY ps.supplier_count ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10
)
SELECT r.r_name, rp.p_name, rp.supplier_count, rp.avg_supplycost, ra.total_revenue
FROM RankedParts rp
LEFT JOIN RegionAggregates ra ON ra.total_revenue > 1000000
JOIN region r ON r.r_regionkey = ra.n_regionkey
WHERE rp.price_rank <= 5
  AND rp.avg_supplycost IS NOT NULL
ORDER BY r.r_name, rp.avg_supplycost DESC;
