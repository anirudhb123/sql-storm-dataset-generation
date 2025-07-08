
WITH SupplierStats AS (
    SELECT s_nationkey,
           COUNT(DISTINCT s_suppkey) AS supplier_count,
           SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
NationPartition AS (
    SELECT n_nationkey,
           n_name,
           ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_nationkey) AS region_row
    FROM nation
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_orders,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c_custkey,
           c_name,
           total_orders,
           order_count
    FROM CustomerOrders
    WHERE total_orders > (SELECT AVG(total_orders) FROM CustomerOrders)
),
PartSupplier AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT n.n_name AS nation_name,
       s.supplier_count,
       COALESCE(c.total_orders, 0) AS total_orders,
       COALESCE(c.order_count, 0) AS order_count,
       COALESCE(p.total_supply_cost, 0) AS total_supply_cost,
       CASE WHEN COALESCE(c.order_count, 0) > 0 THEN 'High Value' ELSE 'Low Value' END AS customer_value_level
FROM NationPartition n
LEFT JOIN SupplierStats s ON n.n_nationkey = s.s_nationkey
LEFT JOIN HighValueCustomers c ON c.c_custkey = n.n_nationkey
LEFT JOIN PartSupplier p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.supplier_count LIMIT 1)
WHERE n.region_row = 1
ORDER BY n.n_name, s.supplier_count DESC;
