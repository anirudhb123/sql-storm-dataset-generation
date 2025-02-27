WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
HighRevenueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_revenue) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(os.total_revenue) > 10000
),
PartSupplierAggregates AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supplycost, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT
    r.r_name,
    COALESCE(hc.total_spent, 0) AS high_revenue_customer_spending,
    psa.p_partkey,
    psa.avg_supplycost,
    psa.supplier_count,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY hc.total_spent DESC NULLS LAST) AS customer_rank,
    CASE WHEN psa.supplier_count > 5 THEN 'Many Suppliers' ELSE 'Few Suppliers' END AS supplier_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN HighRevenueCustomers hc ON n.n_nationkey = hc.c_custkey
JOIN PartSupplierAggregates psa ON psa.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
ORDER BY r.r_name, high_revenue_customer_spending DESC;
