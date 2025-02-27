WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level
    FROM region
    WHERE r_regionkey = 0
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 1000
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
OrderDetails AS (
    SELECT o.o_orderkey,
           l.l_partkey,
           COUNT(l.l_linenumber) AS line_item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, l.l_partkey
),
SupplierRevenue AS (
    SELECT s.s_suppkey,
           SUM(ld.total_line_price) AS revenue
    FROM SupplierStats s
    JOIN OrderDetails ld ON s.s_suppkey = ld.l_linenumber
    GROUP BY s.s_suppkey
)

SELECT rh.r_name AS region_name,
       cs.c_name AS customer_name,
       ss.s_name AS supplier_name,
       SUM(od.total_line_price) AS gross_revenue
FROM RegionHierarchy rh
LEFT JOIN CustomerOrders cs ON rh.r_regionkey = cs.c_custkey 
FULL OUTER JOIN SupplierRevenue ss ON cs.c_custkey = ss.s_suppkey
JOIN OrderDetails od ON od.o_orderkey = ss.s_suppkey 
WHERE od.line_item_count > 2
AND cs.total_spent IS NOT NULL
GROUP BY rh.r_name, cs.c_name, ss.s_name
ORDER BY gross_revenue DESC;
