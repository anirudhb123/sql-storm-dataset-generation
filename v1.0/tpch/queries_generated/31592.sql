WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS total_suppliers, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, ns.total_suppliers, ns.avg_acctbal, os.total_revenue
FROM region r
LEFT JOIN NationSummary ns ON ns.n_nationkey = r.r_regionkey
LEFT JOIN OrderSummary os ON os.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = ns.n_nationkey AND c.c_acctbal IS NOT NULL
)
WHERE r.r_comment IS NOT NULL
ORDER BY ns.avg_acctbal DESC, total_suppliers ASC
HAVING ns.avg_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
UNION
SELECT 'Other' AS r_name, COUNT(*) AS total_suppliers, SUM(s.s_acctbal) AS avg_acctbal, NULL AS total_revenue
FROM supplier s
WHERE s.s_acctbal <= 10000
GROUP BY s.s_nationkey
ORDER BY r_name;

