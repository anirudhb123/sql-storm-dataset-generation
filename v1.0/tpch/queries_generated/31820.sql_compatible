
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, CAST(s_name AS VARCHAR(100)) AS full_name
    FROM supplier
    WHERE s_nationkey = (
        SELECT n_nationkey FROM nation WHERE n_name = 'USA'
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CONCAT(sh.full_name, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, co.order_count, co.total_spent, co.avg_order_value,
           RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > 1000
)
SELECT r.r_name, n.n_name, COUNT(DISTINCT co.c_custkey) AS high_value_customers,
       SUM(co.total_spent) AS total_revenue, AVG(co.avg_order_value) AS avg_order_value,
       STRING_AGG(DISTINCT sh.full_name, ', ') AS supplier_hierarchy
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN HighValueCustomers co ON n.n_nationkey = co.c_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT co.c_custkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;
