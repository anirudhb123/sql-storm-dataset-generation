WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT sp.s_nationkey, sp.s_suppkey, sp.s_name, sp.s_acctbal, sh.level + 1
    FROM supplier sp
        JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, 
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderdate >= DATE '1997-01-01'
    )
),
OrderLineItems AS (
    SELECT o.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM CustomerOrders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.c_custkey
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(NULLIF(s.s_acctbal, 0)) AS total_supplier_balance,
       AVG(l.l_discount) AS avg_discount,
       MAX(o.total_revenue) AS max_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN CustomerOrders c ON s.s_suppkey = c.o_orderkey
LEFT JOIN lineitem l ON c.o_orderkey = l.l_orderkey
LEFT JOIN OrderLineItems o ON c.c_custkey = o.c_custkey
WHERE r.r_name LIKE '%South%'
  AND (s.s_acctbal > 1000 OR s.s_acctbal IS NULL)
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY customer_count DESC;