WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderstatus) AS status_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
)
SELECT r.r_name,
       rs.nation_count,
       rs.total_acctbal,
       COALESCE(os.total_revenue, 0) AS order_revenue,
       os.status_count,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY rs.total_acctbal DESC) AS rank
FROM RegionSummary rs
LEFT JOIN OrderSummary os ON rs.nation_count = os.status_count
JOIN region r ON rs.r_name = r.r_name
WHERE rs.total_acctbal IS NOT NULL
ORDER BY r.r_name, rank;
