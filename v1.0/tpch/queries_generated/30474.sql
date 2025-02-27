WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -12, GETDATE())
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    WHERE ro.o_totalprice > 1000
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_size, ps.ps_availqty,
           AVG(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OutOfStockParts AS (
    SELECT p.p_partkey, p.p_name
    FROM part p
    LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE sp.ps_availqty IS NULL OR sp.ps_availqty = 0
),
CustomerSupplier AS (
    SELECT c.c_custkey, c.c_name, s.s_name, s.s_comment,
           CASE WHEN sh.level IS NULL THEN 'No Hierarchy' ELSE CAST(sh.level AS varchar) END AS hierarchy_level
    FROM HighValueCustomers c
    LEFT JOIN Supplier s ON c.c_nationkey = s.s_nationkey
    LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT c.c_name AS customer_name, s.s_name AS supplier_name, p.p_name AS part_name,
       COALESCE(lp.total_sales, 0) AS total_sales,
       COALESCE(sp.avg_supply_cost, 0) AS average_supply_cost,
       'Out of Stock' AS stock_status
FROM CustomerSupplier c
CROSS JOIN OutOfStockParts p
LEFT JOIN (SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
            FROM lineitem l
            GROUP BY l.l_partkey) lp ON p.p_partkey = lp.l_partkey
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
WHERE c.hierarchy_level <> 'No Hierarchy'
ORDER BY total_sales DESC, supplier_name, customer_name;
