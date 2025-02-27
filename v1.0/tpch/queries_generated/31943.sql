WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_position
    FROM lineitem l
)
SELECT
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(co.total_spent) AS max_customer_spent,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', co.order_count, ' orders)')) AS customers_summary,
    COUNT(DISTINCT sh.s_suppkey) AS distinct_suppliers
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN CustomerOrders co ON co.c_custkey = o.o_custkey
LEFT JOIN OrderDetails l ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE s.s_acctbal IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(ps.ps_availqty) > 1000 OR MAX(co.order_count) > 5
ORDER BY region_name, nation_name;
