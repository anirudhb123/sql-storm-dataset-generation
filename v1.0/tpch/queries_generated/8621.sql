WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 0
),
TopSuppliers AS (
    SELECT DISTINCT s.s_suppkey, s.s_name, n.n_name
    FROM RankedSuppliers s
    JOIN nation n ON s.s_suppkey = n.n_nationkey
    WHERE rank <= 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_quantity, l.l_extendedprice, c.c_mktsegment
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT ts.n_name,
       SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
       COUNT(DISTINCT od.o_orderkey) AS number_of_orders,
       AVG(od.l_quantity) AS average_quantity
FROM TopSuppliers ts
JOIN OrderDetails od ON ts.s_suppkey = od.o_orderkey
GROUP BY ts.n_name
ORDER BY total_sales DESC
LIMIT 10;
