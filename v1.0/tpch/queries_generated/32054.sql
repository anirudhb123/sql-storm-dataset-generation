WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < 1000
),
OrderTotal AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
    AVG(ot.total_price) AS average_order_value,
    COUNT(DISTINCT CASE WHEN ot.total_price > 1000 THEN o.o_orderkey END) AS high_value_orders
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN OrderTotal ot ON o.o_orderkey = ot.o_orderkey
WHERE r.r_name IS NOT NULL
  AND (sh.level IS NULL OR sh.level <= 2)
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY average_order_value DESC, total_suppliers DESC;
