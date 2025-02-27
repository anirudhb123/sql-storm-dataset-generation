WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_totalprice
),
CustomerSpent AS (
    SELECT c.c_custkey, c.c_name, SUM(od.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT rh.r_name, 
       COUNT(DISTINCT ch.c_custkey) AS num_customers, 
       AVG(cs.total_spent) AS avg_spent, 
       COUNT(DISTINCT sh.s_suppkey) AS num_suppliers
FROM region rh
JOIN nation n ON rh.r_regionkey = n.n_regionkey
JOIN customer ch ON n.n_nationkey = ch.c_nationkey
JOIN CustomerSpent cs ON ch.c_custkey = cs.c_custkey
JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
WHERE cs.total_spent > 1000
GROUP BY rh.r_name
ORDER BY avg_spent DESC;
