WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal >= (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal >= (
        SELECT AVG(s_acctbal) FROM supplier
    )
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 3
)
SELECT 
    p.p_name, 
    ps.s_supplycost, 
    sh.level,
    c.total_spent,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_availqty DESC) AS rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN CustomerOrders c ON c.c_custkey IN (
    SELECT DISTINCT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey = p.p_partkey
    )
)
WHERE p.p_size BETWEEN 10 AND 20
  AND COALESCE(c.total_spent, 0) > 500 
  AND sh.level IS NOT NULL
ORDER BY p.p_name, ps.s_supplycost DESC
LIMIT 50;
