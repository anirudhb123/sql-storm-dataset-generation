WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
)
, OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value, COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    SUM(COALESCE(od.total_value, 0)) AS total_order_value,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    MAX(sh.level) AS max_supplier_level,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), ', ') AS product_names
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN OrderDetails od ON od.o_orderkey = (
    SELECT o2.o_orderkey 
    FROM orders o2 
    WHERE o2.o_custkey = od.o_orderkey
    LIMIT 1
)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
GROUP BY n.n_name
HAVING SUM(od.total_value) > 100000
ORDER BY total_order_value DESC
LIMIT 10
