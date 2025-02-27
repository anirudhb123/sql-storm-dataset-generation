
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
SkewedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
    ORDER BY customer_revenue DESC
    LIMIT 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT nh.n_nationkey) AS nation_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_account_balance,
    MAX(SkewedOrders.total_revenue) AS highest_order_revenue,
    STRING_AGG(DISTINCT tc.c_name, ', ') AS top_customers
FROM region r
LEFT JOIN nation nh ON r.r_regionkey = nh.n_regionkey 
LEFT JOIN supplier s ON nh.n_nationkey = s.s_nationkey 
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
LEFT JOIN SkewedOrders ON SkewedOrders.o_orderkey = ps.ps_partkey 
LEFT JOIN TopCustomers tc ON s.s_nationkey = tc.c_custkey 
WHERE r.r_comment IS NOT NULL 
GROUP BY r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 10
ORDER BY r.r_name DESC;
