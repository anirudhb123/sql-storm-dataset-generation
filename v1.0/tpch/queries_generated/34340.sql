WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_order_value,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', sh.level) ORDER BY sh.level) AS suppliers_info
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN TopSuppliers s ON s.s_suppkey = sh.s_suppkey
WHERE o.o_orderstatus IN ('F', 'O')
GROUP BY n.n_name
HAVING SUM(o.o_totalprice) > 100000
ORDER BY customer_count DESC, total_order_value DESC;
