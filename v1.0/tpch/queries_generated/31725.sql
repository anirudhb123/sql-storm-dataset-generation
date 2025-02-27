WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 2
    ORDER BY nation_count DESC
    LIMIT 5
)
SELECT COALESCE(sh.s_nationkey, 'N/A') AS nation_key,
       sh.s_name,
       ps.total_available,
       ps.avg_supply_cost,
       tr.r_name AS region_name,
       COUNT(o.o_orderkey) OVER (PARTITION BY sh.s_nationkey) AS order_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM SupplierHierarchy sh
LEFT JOIN PartStatistics ps ON sh.s_suppkey = ps.p_partkey
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
INNER JOIN TopRegions tr ON tr.r_regionkey = sh.s_nationkey
WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
  AND (sh.s_acctbal IS NOT NULL OR sh.s_acctbal > 10)
ORDER BY total_revenue DESC, order_count ASC
LIMIT 100;
