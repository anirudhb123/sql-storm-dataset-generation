WITH SupplierAggregates AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT sa.s_suppkey, sa.total_cost, ROW_NUMBER() OVER (ORDER BY sa.total_cost DESC) AS rank
    FROM SupplierAggregates sa
),
RankedOrders AS (
    SELECT od.o_orderkey, od.order_total, ROW_NUMBER() OVER (PARTITION BY od.o_orderkey ORDER BY od.order_total DESC) AS order_rank
    FROM OrderDetails od
)
SELECT ns.n_name AS supplier_name, 
       SUM(od.order_total) AS total_order_value, 
       COUNT(DISTINCT od.o_orderkey) AS order_count
FROM RankedOrders ro
JOIN TopSuppliers ts ON ro.order_rank = 1
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation ns ON s.s_nationkey = ns.n_nationkey
GROUP BY ns.n_name
HAVING total_order_value > 10000
ORDER BY total_order_value DESC;
