WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 as level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    COALESCE(os.order_count, 0) AS order_count, 
    COALESCE(ps.total_spent, 0) AS total_spent,
    p.p_partkey,
    p.p_name,
    ps.avg_supplycost,
    ps.supplier_count,
    ps.total_available,
    sh.level
FROM CustomerOrderSummary os
FULL OUTER JOIN Customer c ON os.c_custkey = c.c_custkey
CROSS JOIN PartStatistics ps
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE (c.c_acctbal IS NULL OR c.c_acctbal > 1000)
  AND (p.p_size IS NULL OR p.p_size < 20)
ORDER BY c.c_custkey, p.p_partkey;
