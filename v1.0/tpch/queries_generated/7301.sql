WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING order_total > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(ho.order_total) AS total_spent
    FROM customer c
    JOIN HighValueOrders ho ON c.c_custkey = ho.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierRegionStats AS (
    SELECT r.r_name AS region, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(ps.ps_supplycost * ps.ps_availqty) AS region_supply_value
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
)
SELECT 
    c.c_name AS customer_name, 
    co.order_count, 
    co.total_spent, 
    s.s_name AS supplier_name, 
    ts.total_supply_cost,
    rs.region, 
    rs.supplier_count, 
    rs.region_supply_value
FROM CustomerOrders co
JOIN TopSuppliers ts ON ts.total_supply_cost > 10000
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN SupplierRegionStats rs ON s.s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
WHERE co.order_count > 5
ORDER BY co.total_spent DESC, ts.total_supply_cost ASC;
