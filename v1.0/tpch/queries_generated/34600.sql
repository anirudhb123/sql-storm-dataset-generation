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
HighValueCustomers AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
RevenueByPart AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT p.*, RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM RevenueByPart r
    JOIN part p ON r.p_partkey = p.p_partkey
)
SELECT
    n.n_name AS nation,
    sh.s_name AS supplier_name,
    SUM(rb.total_revenue) AS total_revenue,
    COUNT(DISTINCT hc.c_custkey) AS high_value_customers_count,
    MAX(hc.c_acctbal) AS highest_acctbal,
    AVG(CASE WHEN l.l_discount > 0.1 THEN l.l_discount ELSE NULL END) AS avg_discount_high
FROM nation n
LEFT JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN RankedParts rb ON sh.s_suppkey = rb.p_partkey
LEFT JOIN HighValueCustomers hc ON hc.c_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
WHERE n.r_name IS NOT NULL AND sh.s_acctbal > 5000
GROUP BY n.n_name, sh.s_name
HAVING SUM(rb.total_revenue) > 10000
ORDER BY total_revenue DESC;
