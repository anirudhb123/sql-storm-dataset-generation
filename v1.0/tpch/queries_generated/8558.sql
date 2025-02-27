WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate > DATEADD(year, -1, GETDATE())
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_supplycost, p.p_brand, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
OrderDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM lineitem l
    JOIN RecentOrders ro ON l.l_orderkey = ro.o_orderkey
)
SELECT r.r_name, 
       COUNT(DISTINCT od.l_orderkey) AS total_orders,
       SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
       AVG(sp.ps_supplycost) AS average_supply_cost
FROM RecentOrders ro
JOIN nation n ON ro.c_nationkey = n.n_nationkey
JOIN SupplierParts sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM OrderDetails od WHERE od.l_orderkey = ro.o_orderkey)
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
HAVING AVG(sp.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY total_sales DESC;
