WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           CAST(s_name AS VARCHAR(100)) AS path
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal,
           CONCAT(sh.path, ' -> ', sp.s_name)
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopParts AS (
    SELECT p_partkey, p_name, ps_supplycost
    FROM PartSupplier
    WHERE rn = 1
)
SELECT r.r_name, n.n_name,
       COUNT(DISTINCT c.c_custkey) AS customers_count,
       SUM(co.total_spent) AS total_spent_by_customers,
       AVG(s.s_acctbal) AS average_supplier_acctbal,
       STRING_AGG(DISTINCT tp.p_name, ', ') AS top_parts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN TopParts tp ON s.s_suppkey = tp.p_partkey
WHERE co.total_orders IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(co.total_spent) > 5000
ORDER BY total_spent_by_customers DESC;
