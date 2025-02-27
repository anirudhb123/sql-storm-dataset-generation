WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
),
PartPricing AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_retailprice > 100.00 THEN 'High'
               WHEN p.p_retailprice BETWEEN 50.00 AND 100.00 THEN 'Medium'
               ELSE 'Low'
           END AS price_category
    FROM part p
),
EligibleCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, cn.n_nationkey
    FROM customer c
    JOIN nation cn ON c.c_nationkey = cn.n_nationkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 500.00
),
OrderAnalysis AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
HighValueOrders AS (
    SELECT oa.o_orderkey, oa.total_revenue, ec.c_name, ec.c_acctbal
    FROM OrderAnalysis oa
    JOIN EligibleCustomers ec ON oa.o_custkey = ec.c_custkey
    WHERE oa.total_revenue > 1000.00
)
SELECT 
    p.p_name,
    p.p_retailprice,
    ss.rank_acctbal,
    COALESCE(o.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN o.total_revenue IS NULL THEN 'No Orders'
        WHEN o.total_revenue < 500 THEN 'Low Revenue'
        ELSE 'High Revenue'
    END AS revenue_status
FROM PartPricing p
LEFT JOIN RankedSuppliers ss ON ss.rank_acctbal = 1
LEFT JOIN HighValueOrders o ON p.p_partkey = o.o_orderkey
WHERE (p.p_size IS NOT NULL OR p.p_size < 30)
  AND (p.p_comment LIKE '%urgent%' OR p.p_comment IS NULL)
ORDER BY p.p_retailprice DESC, revenue_status;
