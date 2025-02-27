WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS hierarchy_level
    FROM supplier
    WHERE s_suppkey = 1
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),
OrderSums AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, osc.total_spent
    FROM customer c
    JOIN OrderSums osc ON c.c_custkey = osc.o_custkey
    WHERE osc.total_spent > 10000
    ORDER BY osc.total_spent DESC
    LIMIT 10
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, p.p_retailprice
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
LineItemCalculations AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           l.l_quantity, l.l_discount, l.l_extendedprice,
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS lineno
    FROM lineitem l
)
SELECT 
    sh.s_name AS supplier_name,
    c.c_name AS customer_name,
    ps.p_name AS part_name,
    SUM(li.net_price) AS total_net_price,
    SUM(CASE WHEN li.l_discount > 0.1 THEN li.l_quantity END) AS high_discount_qty,
    COUNT(DISTINCT li.l_orderkey) AS order_count,
    MAX(sh.hierarchy_level) AS supplier_hierarchy_level
FROM SupplierHierarchy sh
JOIN TopCustomers c ON sh.s_nationkey = c.c_nationkey
JOIN PartSuppliers ps ON ps.ps_supplycost < (
    SELECT AVG(ps2.ps_supplycost) 
    FROM partsupp ps2 
    WHERE ps2.ps_availqty > 0
)
JOIN LineItemCalculations li ON li.l_suppkey = sh.s_suppkey
LEFT JOIN region r ON c.c_nationkey = r.r_regionkey 
GROUP BY sh.s_name, c.c_name, ps.p_name
HAVING SUM(li.net_price) IS NOT NULL AND COUNT(li.l_orderkey) > 5
ORDER BY total_net_price DESC;
