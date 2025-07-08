
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, CONCAT('SubSupplier of ', sh.s_name), s.s_acctbal * 0.9, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey + 1
),
AggregatedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
MaxRevenueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM AggregatedOrders o
    WHERE o.total_revenue > 100000
)
SELECT r.r_name,
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       SUM(COALESCE(l.l_extendedprice, 0) * (1 - COALESCE(l.l_discount, 0))) AS total_sales,
       AVG(COALESCE(l.l_discount, 0)) AS avg_discount
FROM nation n
LEFT OUTER JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE r.r_name IS NOT NULL
AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31'
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_sales DESC
LIMIT 10;
