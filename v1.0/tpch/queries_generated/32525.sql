WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000.00
),
TopSuppliers AS (
    SELECT sh.s_nationkey, COUNT(*) AS total_suppliers
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
    HAVING COUNT(*) > 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
CustomerOrders AS (
    SELECT c.c_name, SUM(os.net_revenue) AS total_revenue
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    WHERE c.c_mktsegment IN ('Retail', 'Wholesale')
    GROUP BY c.c_name
),
HighValueCustomers AS (
    SELECT c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS parts_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(ps.ps_partkey) > 3
)
SELECT 
    COALESCE(ns.r_name, 'Unknown') AS region_name,
    SUM(o.total_revenue) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(hvc.c_acctbal) AS avg_high_value_customer_balance
FROM TopSuppliers ts
JOIN nation ns ON ts.n_nationkey = ns.n_nationkey
JOIN HighValueCustomers hvc ON hvc.c_name IN (SELECT c.c_name FROM CustomerOrders co WHERE co.total_revenue > 10000)
LEFT JOIN FilteredSuppliers s ON s.parts_count > 0
LEFT JOIN CustomerOrders o ON o.total_revenue > 50000
GROUP BY ns.r_name
ORDER BY total_revenue DESC
LIMIT 10;
