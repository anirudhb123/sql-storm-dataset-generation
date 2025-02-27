WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_partkey) AS part_count, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS num_orders,
           SUM(od.total_price) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0 
    GROUP BY s.s_suppkey, s.s_name
)
SELECT
    cs.c_name,
    cs.num_orders,
    cs.total_spent,
    sh.level AS supplier_hierarchy_level,
    COALESCE(hv.total_value, 0) AS high_value_total
FROM CustomerOrders cs
LEFT JOIN SupplierHierarchy sh ON cs.c_custkey = sh.s_nationkey
LEFT JOIN HighValueSuppliers hv ON sh.s_suppkey = hv.s_suppkey
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY cs.total_spent DESC, sh.level NULLS LAST
FETCH FIRST 10 ROWS ONLY;
