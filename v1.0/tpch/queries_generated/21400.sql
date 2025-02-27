WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey <> sh.s_suppkey
    WHERE sh.level < 3
),

RegionWithAggregate AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(COALESCE(foo.s_acctbal, 0)) AS total_acctbal,
           STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN (
        SELECT s.s_nationkey, SUM(s.s_acctbal) AS s_acctbal
        FROM supplier s
        WHERE s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2)
        GROUP BY s.s_nationkey
    ) AS foo ON s.s_nationkey = foo.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),

OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_custkey
)

SELECT rh.r_name, rh.nation_count, rh.total_acctbal,
       COALESCE(os.total_revenue, 0) AS total_revenue,
       COUNT(DISTINCT sh.s_suppkey) AS supply_chain_count
FROM RegionWithAggregate rh
LEFT JOIN OrderStats os ON rh.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_name LIKE '%Supplier%' LIMIT 1)
FULL OUTER JOIN SupplierHierarchy sh ON rh.nation_count > 0
GROUP BY rh.r_name, rh.nation_count, rh.total_acctbal, os.total_revenue
ORDER BY rh.total_acctbal DESC, rh.nation_count ASC
LIMIT 10 OFFSET 5;
