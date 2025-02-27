WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ts.total_cost + SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN TopSuppliers ts ON s.s_suppkey <> ts.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, ts.total_cost
), RankedSuppliers AS (
    SELECT ts.s_suppkey, ts.s_name, ts.total_cost,
           RANK() OVER (ORDER BY ts.total_cost DESC) AS rank
    FROM TopSuppliers ts
), CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), HighValueOrders AS (
    SELECT *
    FROM CustomerOrders
    WHERE order_rank <= 3
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count, SUM(o.o_totalprice) AS total_sales,
       AVG(l.l_extendedprice) AS avg_line_value, MAX(s.total_cost) AS max_supplier_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN HighValueOrders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN RankedSuppliers s ON l.l_suppkey = s.s_suppkey
WHERE r.r_name LIKE '%East%' AND o.o_totalprice IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_sales DESC;
