
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
AverageOrderValue AS (
    SELECT AVG(total_spent) AS avg_order_value
    FROM CustomerOrders
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT avg_order_value FROM AverageOrderValue)
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN FilteredParts fp ON ps.ps_partkey = fp.p_partkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    sh.s_suppkey AS supp_key,
    sh.s_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN COALESCE(ss.total_supply_cost, 0) > (SELECT avg_order_value FROM AverageOrderValue)
        THEN 'High Supplier'
        ELSE 'Low Supplier'
    END AS supplier_category
FROM SupplierHierarchy sh
LEFT JOIN SupplierStats ss ON sh.s_suppkey = ss.s_suppkey
WHERE sh.level < 3
ORDER BY supplier_category, total_supply_cost DESC;
