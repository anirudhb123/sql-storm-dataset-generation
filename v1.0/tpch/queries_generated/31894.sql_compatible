
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.order_count, c.total_spent, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.total_spent DESC) AS rn
    FROM CustomerOrders c
    WHERE c.total_spent IS NOT NULL AND c.order_count > 5
)
SELECT 
    ph.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name, 
    n.n_name AS nation_name, 
    COUNT(DISTINCT o.o_orderkey) AS orders_count
FROM part ph
JOIN lineitem l ON ph.p_partkey = l.l_partkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey 
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN orders o ON l.l_orderkey = o.o_orderkey 
INNER JOIN nation n ON s.s_nationkey = n.n_nationkey 
LEFT JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey 
WHERE ph.p_size > 10 AND (s.s_acctbal IS NULL OR s.s_acctbal < 500)
GROUP BY ph.p_name, s.s_name, n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY revenue DESC;
