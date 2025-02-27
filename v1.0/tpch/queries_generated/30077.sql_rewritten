WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sh.hierarchy_level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > 5000
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN RecentOrders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT l.l_orderkey) AS total_orders,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name, 
       COALESCE(h.hierarchy_level, 0) AS supplier_hierarchy_level,
       tc.total_spent,
       sp.total_orders,
       sp.avg_order_value
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy h ON n.n_nationkey = h.s_nationkey
LEFT JOIN TopCustomers tc ON n.n_nationkey = tc.c_custkey
LEFT JOIN SupplierPerformance sp ON h.s_suppkey = sp.s_suppkey
WHERE r.r_name IS NOT NULL
  AND (tc.total_spent IS NULL OR sp.avg_order_value > 1000)
ORDER BY r.r_name, total_spent DESC NULLS LAST;