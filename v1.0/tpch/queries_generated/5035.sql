WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT r.r_name, rs.nation_name, rs.s_name, rs.s_acctbal
    FROM RankedSuppliers rs
    JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = rs.nation_name)
    WHERE rs.supplier_rank <= 3
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT ts.r_name, ts.nation_name, SUM(od.o_totalprice) AS total_order_value,
       COUNT(DISTINCT od.o_orderkey) AS total_orders,
       AVG(od.l_quantity) AS avg_line_quantity,
       SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue_after_discount
FROM TopSuppliers ts
JOIN OrderDetails od ON ts.s_name = od.l_suppkey
GROUP BY ts.r_name, ts.nation_name
ORDER BY total_order_value DESC
LIMIT 10;
