WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> sh.s_suppkey
),
OrderStats AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           COUNT(l.l_orderkey) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(o.o_totalprice) OVER (PARTITION BY o.o_orderkey) AS avg_order_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(tc.total_spent, 0) AS total_spent_by_top_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(os.total_revenue) AS total_revenue_by_orders,
    AVG(os.avg_order_price) AS average_order_value,
    sh.level AS supplier_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN OrderStats os ON os.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o
    JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
)
LEFT JOIN TopCustomers tc ON tc.c_custkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
GROUP BY r.r_name, n.n_name, tc.total_spent, sh.level
ORDER BY region_name, nation_name;
