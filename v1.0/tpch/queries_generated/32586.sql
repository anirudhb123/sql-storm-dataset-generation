WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 10000
    UNION ALL
    SELECT s.n_nationkey, sp.s_suppkey, sp.s_name, sh.level + 1
    FROM supplier sp
    JOIN nation n ON sp.s_nationkey = n.n_nationkey
    JOIN SupplierHierarchy sh ON n.n_regionkey = sh.s_nationkey
    WHERE sp.s_acctbal < sh.supp_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
CustomerActivity AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(od.revenue) AS total_revenue,
       MIN(ca.total_spent) AS min_spent,
       MAX(ca.total_spent) AS max_spent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerActivity ca ON c.c_custkey = ca.c_custkey
LEFT JOIN OrderDetails od ON ca.order_count > 0 AND od.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
GROUP BY r.r_name
HAVING SUM(od.revenue) IS NOT NULL AND COUNT(DISTINCT c.c_custkey) > 0
ORDER BY total_revenue DESC;
