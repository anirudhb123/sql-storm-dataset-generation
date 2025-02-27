WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'  -- Assuming 'O' is for orders in progress
    UNION ALL
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5  -- Limiting levels of recursion
),
SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available,
           COUNT(s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemAggregates AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_tax) AS avg_tax,
           COUNT(l.l_linenumber) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT c.c_name, co.total_spent, co.order_count,
       la.total_revenue, la.avg_tax, COALESCE(ss.total_available, 0) AS total_available,
       CASE 
           WHEN co.total_spent IS NULL THEN 'No Orders'
           WHEN co.total_spent < 1000 THEN 'Low Value Customer'
           ELSE 'High Value Customer'
       END AS customer_category
FROM CustomerOrders co
LEFT JOIN LineItemAggregates la ON co.order_count = la.item_count
LEFT JOIN SupplierStats ss ON ss.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')))
WHERE co.order_count > 0 OR ss.total_available > 0
ORDER BY co.total_spent DESC, la.total_revenue ASC;
