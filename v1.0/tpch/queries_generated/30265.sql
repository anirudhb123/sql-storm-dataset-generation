WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r2.r_regionkey, r2.r_name, rh.level + 1
    FROM region r2
    JOIN RegionHierarchy rh ON r2.r_regionkey > rh.r_regionkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderActivity AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name, 
       psi.p_name, 
       c.c_name,
       c.total_spent,
       COALESCE(ss.total_sales, 0) AS supplier_sales,
       CASE 
           WHEN c.order_count IS NULL THEN 'No Orders'
           ELSE 'Orders Made'
       END AS order_status
FROM RegionHierarchy r
LEFT JOIN PartSupplierInfo psi ON psi.total_available_qty > 100
LEFT JOIN CustomerOrderActivity c ON c.order_count > 5
LEFT JOIN SupplierSales ss ON ss.total_sales > 10000
WHERE r.level < 2
ORDER BY r.r_name, c.total_spent DESC, ss.total_sales DESC;
