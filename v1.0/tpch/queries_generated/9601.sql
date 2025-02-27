WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, s.s_suppkey
),
TopSuppliers AS (
    SELECT n_name, s_suppkey, total_cost,
           RANK() OVER (PARTITION BY n_name ORDER BY total_cost DESC) AS supplier_rank
    FROM NationSupplier
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_partkey, l.l_quantity, l.l_extendedprice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
PartCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS part_total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT ts.n_name, ts.s_suppkey, ts.total_cost, ro.o_orderkey, ro.o_orderdate, ro.l_partkey, ro.l_quantity, ro.l_extendedprice, pc.part_total_cost
FROM TopSuppliers ts
JOIN RecentOrders ro ON ts.n_name = ro.l_partkey
JOIN PartCosts pc ON ro.l_partkey = pc.ps_partkey
WHERE ts.supplier_rank <= 5
ORDER BY ts.n_name, ts.total_cost DESC, ro.o_orderdate DESC;
