WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  -- Start with suppliers above average account balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal  -- Recurrent filter: next level must have higher account balance
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
SupplierRevenue AS (
    SELECT s.s_suppkey, SUM(os.total_revenue) AS supp_revenue
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey))
    GROUP BY s.s_suppkey
),
CombinedResults AS (
    SELECT
        sh.s_suppkey,
        sh.s_name,
        sr.supp_revenue,
        sh.level,
        ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sr.supp_revenue DESC) AS rank
    FROM SupplierHierarchy sh
    LEFT JOIN SupplierRevenue sr ON sh.s_suppkey = sr.s_suppkey
)
SELECT
    cr.s_suppkey,
    cr.s_name,
    COALESCE(cr.supp_revenue, 0) AS total_revenue,
    cr.level,
    cr.rank
FROM CombinedResults cr
WHERE cr.rank <= 5
ORDER BY cr.level, cr.rank;
