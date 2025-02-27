WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT sr.s_suppkey, sr.s_name, sr.s_acctbal, sh.level + 1
    FROM supplier sr
    JOIN SupplierHierarchy sh ON sr.s_acctbal > sh.s_acctbal * 1.1
),
CustomerOrderStats AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value,
           COUNT(o.o_orderkey) AS total_orders, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_available,
           ARRAY_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')')) AS suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(ocs.total_order_value) AS avg_order_value,
       SUM(ocs.total_orders) AS total_orders,
       ph.total_available,
       ph.suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerOrderStats ocs ON c.c_custkey = ocs.c_custkey
LEFT JOIN PartSupplier ph ON ph.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 100 AND ps.ps_supplycost < 50.00
)
WHERE ocs.rank <= 3 OR ocs.total_order_value IS NULL
GROUP BY r.r_name, ph.total_available, ph.suppliers
HAVING SUM(COALESCE(ocs.total_order_value, 0)) > 1000000
ORDER BY customer_count DESC, avg_order_value DESC;
