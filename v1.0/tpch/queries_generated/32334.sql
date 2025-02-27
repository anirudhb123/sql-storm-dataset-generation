WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 10
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM orders o
    GROUP BY o.o_custkey
),
CustomerOrderInfo AS (
    SELECT c.c_custkey, c.c_name, os.total_spent, os.total_orders,
           RANK() OVER (ORDER BY os.total_spent DESC) AS rank_spent
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT c.c_name, c.c_custkey, 
       COALESCE(d.p_name, 'No Parts') AS part_name,
       CASE 
           WHEN os.total_orders IS NULL THEN 'No Orders'
           ELSE CONCAT('Total Orders: ', os.total_orders)
       END AS order_info,
       sh.level AS supplier_level
FROM customer c
LEFT JOIN CustomerOrderInfo os ON c.c_custkey = os.c_custkey
LEFT JOIN PartDetails d ON os.total_spent > 5000.00 AND d.rn <= 3
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE c.c_mktsegment IN ('TECHNOLOGY', 'FURNITURE')
  AND (os.total_spent IS NULL OR os.total_spent > 10000.00)
ORDER BY c.c_name, supplier_level DESC;
