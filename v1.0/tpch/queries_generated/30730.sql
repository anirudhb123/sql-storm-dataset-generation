WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, sh.level + 1
    FROM supplier sh
    JOIN SupplierHierarchy shier ON sh.s_suppkey = shier.s_suppkey
    WHERE shier.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerRevenue AS (
    SELECT c.c_custkey, SUM(os.total_revenue) AS customer_spending
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey
),
NationSupport AS (
    SELECT n.n_nationkey, COUNT(DISTINCT ps.ps_partkey) AS supported_parts
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey
),
RankedCustomers AS (
    SELECT cr.c_custkey, cr.customer_spending,
           RANK() OVER (ORDER BY cr.customer_spending DESC) AS revenue_rank
    FROM CustomerRevenue cr
)
SELECT n.r_name, n.supported_parts, r.customer_spending, r.revenue_rank
FROM NationSupport n
FULL OUTER JOIN RankedCustomers r ON r.c_custkey = n.n_nationkey
WHERE n.supported_parts > 10 OR r.customer_spending IS NOT NULL
ORDER BY n.r_name NULLS LAST, r.customer_spending DESC
LIMIT 100;
