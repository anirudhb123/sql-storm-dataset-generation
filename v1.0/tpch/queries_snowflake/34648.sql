
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT DISTINCT p.p_partkey, p.p_name, p.p_retailprice,
       COALESCE(SH.level, 0) AS supply_level,
       COALESCE(COS.total_orders, 0) AS customer_orders,
       COALESCE(COS.total_spent, 0) AS customer_spending
FROM part p
LEFT JOIN SupplierHierarchy SH ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = SH.s_suppkey)
LEFT JOIN CustomerOrderStats COS ON COS.total_orders > 0
WHERE p.p_retailprice BETWEEN 10 AND 100
  AND (p.p_comment IS NULL OR p.p_comment LIKE '%new%')
ORDER BY p.p_partkey
LIMIT 100; 
