WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT ss.s_suppkey, ss.s_name, ss.part_count, ss.total_supply_cost
    FROM SupplierStats ss
    WHERE ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, li.l_partkey, li.l_quantity, li.l_extendedprice
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_shipdate >= DATE '2022-01-01' AND li.l_shipdate < DATE '2023-01-01'
)
SELECT cv.c_custkey, cv.c_name, hvs.s_suppkey, hvs.s_name, hv.total_spent, hv.part_count, hv.total_supply_cost, SUM(od.l_extendedprice * od.l_quantity) AS total_order_value
FROM CustomerOrders cv
JOIN HighValueSuppliers hvs ON cv.total_spent > 10000
JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cv.c_custkey)
GROUP BY cv.c_custkey, cv.c_name, hvs.s_suppkey, hvs.s_name, hv.total_spent, hv.part_count, hv.total_supply_cost
ORDER BY total_order_value DESC
LIMIT 10;
