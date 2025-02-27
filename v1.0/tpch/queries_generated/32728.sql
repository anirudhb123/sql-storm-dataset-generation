WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
      AND sh.level < 5
),
CustomerPurchase AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartSum AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
QualifiedCustomers AS (
    SELECT c.c_custkey, c.c_name, CASE 
        WHEN cu.total_spent IS NULL THEN 0 
        ELSE cu.total_spent
    END AS total_spent
    FROM customer c
    LEFT JOIN CustomerPurchase cu ON c.c_custkey = cu.c_custkey
    WHERE c.c_acctbal > 1000 
)

SELECT 
    rh.level,
    qs.c_name,
    ps.total_cost,
    AVG(qs.total_spent) OVER (PARTITION BY rh.level) AS avg_spent_per_level
FROM SupplierHierarchy rh
JOIN RankedSuppliers rs ON rh.s_nationkey = rs.s_suppkey
JOIN SupplierPartSum ps ON rs.s_suppkey = ps.p_partkey
JOIN QualifiedCustomers qs ON qs.c_custkey = rh.s_nationkey
WHERE ps.total_cost IS NOT NULL AND qs.total_spent > 0
ORDER BY rh.level, qs.total_spent DESC
LIMIT 50;
