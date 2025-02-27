WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (sh.s_acctbal * 0.5)
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_suppkey) AS supplier_count,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrderCounts AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT r.r_name AS region,
       n.n_name AS nation,
       p.p_name AS part_name,
       SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
       SUM(o.total_revenue) AS total_revenue,
       AVG(co.order_count) AS average_customer_orders,
       MAX(sh.level) AS max_supplier_hierarchy_level
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderSummary o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerOrderCounts co ON s.s_nationkey = co.c_custkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_retailprice > 20 AND (n.n_name IS NOT NULL OR s.s_acctbal IS NOT NULL)
GROUP BY r.r_name, n.n_name, p.p_name
HAVING SUM(l.l_quantity) > 100
ORDER BY total_revenue DESC, region, nation;
