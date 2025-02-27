WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderStatistics AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_custkey
),
CustomerSupplier AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, so.total_orders, so.total_spent,
           sh.s_suppkey, sh.s_name, sh.s_acctbal AS supplier_acctbal
    FROM customer c
    LEFT JOIN OrderStatistics so ON c.c_custkey = so.o_custkey
    LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
)
SELECT DISTINCT cs.c_custkey, cs.c_name, cs.total_orders, 
       CASE WHEN cs.total_orders IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status,
       CONCAT('Total Spent: ', COALESCE(CAST(cs.total_spent AS VARCHAR), '0')) AS total_spent_description,
       CONCAT('Supplier: ', COALESCE(cs.s_name, 'No Supplier')) AS supplier_info,
       CASE WHEN cs.supplier_acctbal > 1000 THEN 'High Value Supplier' ELSE 'Low Value Supplier' END AS supplier_value
FROM CustomerSupplier cs
ORDER BY cs.c_custkey;
