WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 3
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(od.total_revenue) AS total_spent
    FROM customer c
    JOIN OrderDetails od ON c.c_custkey = od.o_orderkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT DISTINCT p.p_partkey, p.p_name, p.p_retailprice,
       COALESCE(SUM(ps.ps_availqty), 0) AS total_available,
       COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS price_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN TopCustomers tc ON sh.s_nationkey = tc.c_custkey
WHERE p.p_size BETWEEN 1 AND 10 
  AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size)
  AND (sh.level IS NULL OR sh.level < 2)
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
HAVING COUNT(DISTINCT tc.c_custkey) > 0
ORDER BY price_rank;
