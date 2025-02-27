WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, sh.s_name, sh.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name,
       COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
       COUNT(DISTINCT tp.p_partkey) AS top_part_count,
       SUM(co.order_count) AS total_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN TopParts tp ON s.s_suppkey = tp.p_partkey
LEFT JOIN CustomerOrders co ON s.s_nationkey = co.c_custkey
WHERE r.r_comment IS NOT NULL 
  AND (COALESCE(tp.total_revenue, 0) > 5000 OR co.order_count > 10)
GROUP BY r.r_name
ORDER BY total_suppliers DESC, total_orders DESC
LIMIT 10;
