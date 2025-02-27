WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.level * 5000
),
FrequentCustomers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
LargeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    nh.n_name AS nation_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    COALESCE(SUM(f.order_count), 0) AS frequent_customer_count,
    MAX(lo.total_amount) AS largest_order
FROM nation nh
LEFT JOIN SupplierHierarchy sh ON nh.n_nationkey = sh.s_nationkey
LEFT JOIN FrequentCustomers f ON f.c_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = nh.n_nationkey
)
LEFT JOIN LargeOrders lo ON lo.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = nh.n_nationkey
    )
)
WHERE nh.n_name IS NOT NULL
GROUP BY nh.n_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 0 OR COALESCE(SUM(f.order_count), 0) > 0
ORDER BY largest_order DESC NULLS LAST;
