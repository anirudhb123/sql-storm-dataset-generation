WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.nationkey = sh.nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),

OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),

CustomerOrderDetails AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(os.total_revenue) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
)

SELECT ph.s_name AS supplier_name,
       ph.s_address AS supplier_address,
       co.c_name AS customer_name,
       co.order_count,
       co.total_spent,
       ph.level
FROM SupplierHierarchy ph
JOIN CustomerOrderDetails co ON co.order_count > 5
WHERE ph.s_nationkey IN (
    SELECT n.n_nationkey FROM nation n WHERE n.n_comment IS NOT NULL
) 
ORDER BY total_spent DESC
LIMIT 10;
