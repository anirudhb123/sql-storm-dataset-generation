WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
HighValuedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) as rank
    FROM customer c
    WHERE c.c_acctbal >= 5000
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    NH.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(od.total_revenue) AS total_revenue,
    AVG(COALESCE(sh.s_acctbal, 0)) AS avg_supplier_bal
FROM HighValuedCustomers c
LEFT JOIN NationalRegion NH ON c.c_nationkey = NH.n_nationkey
LEFT JOIN OrderDetails od ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey LIMIT 1)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
GROUP BY NH.n_name
HAVING SUM(od.total_revenue) > 100000
ORDER BY customer_count DESC, total_revenue DESC;
