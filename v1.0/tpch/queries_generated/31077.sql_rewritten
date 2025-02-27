WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = 
      (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
    WHERE c.c_acctbal < ch.c_acctbal
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey
),
SupplierRatings AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, COUNT(o.o_orderkey) AS order_count
    FROM CustomerHierarchy ch
    LEFT JOIN RecentOrders o ON ch.c_custkey = o.o_custkey
    GROUP BY ch.c_custkey, ch.c_name, ch.c_acctbal
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT 
    hv.c_custkey AS customer_id,
    hv.c_name AS customer_name,
    COALESCE(ROUND(AVG(sr.avg_supply_cost), 2), 0) AS avg_supplier_cost,
    hv.order_count,
    CASE 
        WHEN hv.order_count > 10 THEN 'High Value'
        WHEN hv.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM HighValueCustomers hv
LEFT JOIN SupplierRatings sr ON hv.c_custkey = sr.s_suppkey
GROUP BY hv.c_custkey, hv.c_name, hv.c_acctbal, hv.order_count
ORDER BY hv.c_acctbal DESC, customer_value_category;