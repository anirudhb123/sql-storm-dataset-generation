WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    ORDER BY total_supply_cost DESC
),
TopSuppliers AS (
    SELECT s.s_nationkey, s.s_name, r.r_name
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.total_supply_cost IN (SELECT DISTINCT total_supply_cost FROM RankedSuppliers ORDER BY total_supply_cost DESC LIMIT 10)
),
SalesData AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT t.s_name, t.r_name, SUM(sd.total_sales) AS total_sales
FROM TopSuppliers t
JOIN SalesData sd ON t.s_nationkey = (SELECT n.n_nationkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_name = t.s_name)
GROUP BY t.s_name, t.r_name
ORDER BY total_sales DESC
LIMIT 5;
