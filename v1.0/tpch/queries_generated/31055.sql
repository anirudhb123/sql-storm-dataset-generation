WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER(PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
HighValueSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    GROUP BY sh.s_suppkey, sh.s_name
    HAVING SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    c.c_name AS customer_name,
    c.order_count,
    CASE 
        WHEN c.order_count = 0 THEN 'No Orders'
        ELSE CONCAT('Total Spent: $', ROUND(c.total_spent, 2))
    END AS order_statistics,
    s.s_name AS supplier_name,
    sh.level AS supplier_level,
    CASE 
        WHEN s.s_name IS NULL THEN 'No Supplier'
        ELSE CONCAT('Total Supply Cost: $', ROUND(HS.total_supply_cost, 2))
    END AS supplier_statistics
FROM CustomerOrders c
LEFT JOIN HighValueSuppliers HS ON HS.total_supply_cost > (SELECT AVG(total_supply_cost) FROM HighValueSuppliers)
LEFT JOIN supplier s ON c.c_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE c.rank <= 10
ORDER BY c.total_spent DESC NULLS LAST;
