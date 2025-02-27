WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal > 5000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -3, GETDATE())
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerOrderSummary AS (
    SELECT ch.c_custkey, ch.c_name, ro.total_order_value, COUNT(ro.o_orderkey) AS order_count
    FROM CustomerHierarchy ch
    LEFT JOIN RecentOrders ro ON ch.c_custkey = ro.o_custkey
    GROUP BY ch.c_custkey, ch.c_name, ro.total_order_value
)
SELECT co.c_name AS customer_name,
       COALESCE(SUM(co.total_order_value), 0) AS total_spent,
       COALESCE(SUM(CASE WHEN s.total_supply_cost IS NOT NULL THEN s.total_supply_cost ELSE 0 END), 0) AS total_supplier_cost,
       COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
       DENSE_RANK() OVER (ORDER BY COALESCE(SUM(co.total_order_value), 0) DESC) AS spending_rank
FROM CustomerOrderSummary co
FULL OUTER JOIN SupplierStats s ON co.c_custkey = s.s_suppkey
WHERE co.total_spent IS NOT NULL OR s.total_supply_cost IS NOT NULL
GROUP BY co.c_name
ORDER BY spending_rank, customer_name;
