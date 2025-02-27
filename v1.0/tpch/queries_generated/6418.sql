WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey
    FROM RankedSuppliers s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.rank <= 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_quantity, l.l_discount, l.l_tax, l.l_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate BETWEEN DATE '2023-10-01' AND DATE '2023-10-31'
)
SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(od.o_totalprice) AS total_revenue,
       SUM(ld.l_discount * od.o_totalprice) AS total_discounted_revenue, AVG(ps.ps_supplycost) AS avg_supply_cost
FROM TopSuppliers ts
JOIN nation n ON ts.s_nationkey = n.n_nationkey
JOIN OrderDetails od ON ts.ps_partkey = od.l_orderkey
GROUP BY n.n_name
ORDER BY total_orders DESC, total_revenue DESC
LIMIT 10;
