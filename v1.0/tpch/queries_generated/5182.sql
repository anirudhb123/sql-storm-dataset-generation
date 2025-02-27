WITH RecentOrders AS (
    SELECT o_orderkey, o_orderdate, o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -12, GETDATE())
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_retailprice, s.s_acctbal
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 50.00
),
TopSuppliers AS (
    SELECT s.n_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM SupplierParts ps 
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.n_nationkey
    ORDER BY total_supply_value DESC
    LIMIT 5
),
OrderDetails AS (
    SELECT ro.o_orderkey, ro.o_totalprice, li.l_extendedprice, li.l_discount
    FROM RecentOrders ro
    JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
)
SELECT r.n_name AS nation_name, COUNT(od.o_orderkey) AS order_count, AVG(od.o_totalprice) AS avg_order_value, SUM(od.l_extendedprice) AS total_extended_price, SUM(od.l_discount) AS total_discount
FROM OrderDetails od
JOIN RecentOrders ro ON od.o_orderkey = ro.o_orderkey
JOIN nation r ON ro.c_nationkey = r.n_nationkey
WHERE r.n_nationkey IN (SELECT n_nationkey FROM TopSuppliers)
GROUP BY r.n_name
HAVING AVG(od.o_totalprice) > 100
ORDER BY total_extended_price DESC;
