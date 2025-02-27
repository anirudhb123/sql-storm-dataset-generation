WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 2000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal * 1.1
),
OrderRevenue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '2023-01-01'
    GROUP BY o.o_orderkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(ol.total_revenue) AS customer_revenue,
           RANK() OVER (ORDER BY SUM(ol.total_revenue) DESC) AS revenue_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderRevenue ol ON o.o_orderkey = ol.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COALESCE(SH.s_name, 'No Supplier') AS supplier_name,
       COUNT(DISTINCT rc.c_custkey) AS customer_count,
       SUM(rc.customer_revenue) AS total_revenue,
       MAX(rc.customer_revenue) AS max_revenue,
       AVG(rc.customer_revenue) AS avg_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy SH ON SH.s_suppkey = s.s_suppkey
LEFT JOIN RankedCustomers rc ON rc.c_custkey = o.o_custkey
WHERE r.r_name IS NOT NULL OR (SH.s_name IS NULL AND rc.customer_revenue IS NOT NULL)
GROUP BY r.r_name, SH.s_name
HAVING SUM(rc.customer_revenue) > 50000
ORDER BY total_revenue DESC;
