WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal >= sh.s_acctbal AND sh.level < 5
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    c.c_name,
    COALESCE(c.total_orders, 0) AS total_orders,
    COALESCE(c.total_spent, 0) AS total_spent,
    p.p_name,
    ps.total_supplycost,
    MAX(l.total_lineitem_value) AS max_lineitem_value,
    sh.level AS supplier_level
FROM CustomerOrders c
FULL OUTER JOIN PartSupplier p ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0
) 
LEFT JOIN LineItemSummary l ON l.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey
)
GROUP BY c.c_name, p.p_name, ps.total_supplycost, sh.level
HAVING COALESCE(c.total_orders, 0) > 5 OR COALESCE(p.total_supplycost, 0) > 5000
ORDER BY total_spent DESC, supplier_level ASC;
