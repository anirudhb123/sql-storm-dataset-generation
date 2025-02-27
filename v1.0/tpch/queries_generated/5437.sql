WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 5000
), RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
), SupplierOrderDetails AS (
    SELECT so.o_orderkey, so.o_custkey, rs.s_name AS supplier_name, ro.total_order_value
    FROM RecentOrders so
    JOIN lineitem li ON so.o_orderkey = li.l_orderkey
    JOIN RankedSuppliers rs ON li.l_suppkey = rs.s_suppkey
    JOIN HighValueCustomers ro ON so.o_custkey = ro.c_custkey
)
SELECT sod.o_orderkey, sod.supplier_name, sod.total_order_value
FROM SupplierOrderDetails sod
ORDER BY sod.total_order_value DESC, sod.o_orderkey ASC
LIMIT 50;
