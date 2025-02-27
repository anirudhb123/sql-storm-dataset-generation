WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerRecentOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS recent_order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
QualifiedSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, c.c_name, coalesce(cr.recent_order_count, 0) AS recent_order_count
    FROM SupplierHierarchy sh
    LEFT JOIN CustomerRecentOrders cr ON sh.s_nationkey = cr.c_custkey
    WHERE sh.hierarchy_level <= 3
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(m.recent_order_count, 0) AS customer_orders
FROM part p
JOIN PartSupplierInfo ps ON p.p_partkey = ps.p_partkey AND ps.rn = 1
LEFT JOIN QualifiedSuppliers s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN CustomerRecentOrders m ON m.c_custkey = s.s_nationkey
WHERE p.p_retailprice > 100.00
ORDER BY p.p_partkey, supplier_name
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
