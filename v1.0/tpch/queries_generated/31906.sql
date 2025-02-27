WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 3
),
OrderStats AS (
    SELECT o.o_orderkey, 
           COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_revenue) AS nation_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
RegionNationRevenue AS (
    SELECT r.r_regionkey, r.r_name, n.n_name, COALESCE(n.nation_revenue, 0) AS total_nation_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT r.r_name,
       SUM(rnr.total_nation_revenue) AS total_revenue,
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       MAX(sh.s_acctbal) AS highest_account_balance
FROM RegionNationRevenue rnr
LEFT JOIN SupplierHierarchy sh ON sh.s_acctbal IS NOT NULL
WHERE rnr.total_nation_revenue > 500000
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY total_revenue DESC, highest_account_balance DESC;
