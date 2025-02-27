WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2021-01-01' AND o.o_orderdate < '2021-12-31'
), AggregatedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2021-01-01'
    GROUP BY l.l_orderkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COALESCE(COUNT(DISTINCT sh.s_suppkey), 0) AS supplier_count,
       COUNT(DISTINCT co.c_custkey) AS customer_count,
       COALESCE(SUM(ali.total_revenue), 0) AS total_revenue,
       AVG(co.total_spent) AS avg_spent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_nationkey
LEFT JOIN AggregatedLineItems ali ON co.total_orders > 0

WHERE (r.r_name LIKE 'S%' OR r.r_name IS NULL)
GROUP BY r.r_name
ORDER BY total_revenue DESC, supplier_count DESC;
