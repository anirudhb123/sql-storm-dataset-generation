
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT l.l_suppkey) AS unique_suppliers, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank_acctbal
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
    )
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice ELSE 0 END) AS total_discounted_price,
    COUNT(DISTINCT sh.s_suppkey) AS suppliers_count,
    AVG(c.c_acctbal) AS average_customer_balance
FROM partsupp ps
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN HighValueCustomers c ON c.c_custkey = (
    SELECT DISTINCT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderkey = l.l_orderkey 
    LIMIT 1
)
GROUP BY ps.ps_partkey, p.p_name, l.l_discount, sh.s_suppkey, c.c_custkey, c.c_acctbal
HAVING COALESCE(SUM(ps.ps_availqty), 0) > 100
ORDER BY total_available_quantity DESC, p.p_name ASC;
