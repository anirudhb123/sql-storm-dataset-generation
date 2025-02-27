WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000.00 AND sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_revenue) AS national_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedNationalRevenue AS (
    SELECT nr.n_nationkey, nr.n_name, nr.national_revenue,
           RANK() OVER (ORDER BY nr.national_revenue DESC) AS revenue_rank
    FROM NationRevenue nr
    WHERE nr.national_revenue IS NOT NULL
)
SELECT sh.s_name, sh.s_address, sh.s_acctbal, rnr.n_name, rnr.national_revenue, rnr.revenue_rank
FROM SupplierHierarchy sh
JOIN RankedNationalRevenue rnr ON sh.s_nationkey = rnr.n_nationkey
WHERE sh.level <= 3 AND (sh.s_acctbal > 5000.00 OR rnr.revenue_rank < 10)
ORDER BY rnr.national_revenue DESC, sh.s_acctbal ASC;
