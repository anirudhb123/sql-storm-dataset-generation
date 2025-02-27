WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = (SELECT MIN(ps_suppkey) FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_retailprice > 50))
    WHERE sh.level < 5
),
OrderSummaries AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerPurchases AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(os.total_sales) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderSummaries os ON o.o_orderkey = os.o_orderkey
    GROUP BY c.c_custkey
),
SupplierRegion AS (
    SELECT s.s_suppkey, n.n_nationkey, r.r_regionkey, r.r_name,
           ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT sr.r_name,
       COUNT(DISTINCT ch.c_custkey) AS total_customers,
       SUM(ch.total_spent) AS total_revenue,
       AVG(sh.s_acctbal) AS avg_supplier_balance,
       MAX(sh.level) AS max_level
FROM SupplierHierarchy sh
JOIN SupplierRegion sr ON sh.s_suppkey = sr.s_suppkey
JOIN CustomerPurchases ch ON sr.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'United States')
GROUP BY sr.r_name
HAVING SUM(ch.total_spent) > 10000
ORDER BY total_revenue DESC;
