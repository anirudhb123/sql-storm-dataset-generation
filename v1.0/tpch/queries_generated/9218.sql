WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY total_cost DESC) AS rank
    FROM RankedSuppliers
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ts.nation_name, ts.s_name, ts.total_cost, os.total_revenue
FROM TopSuppliers ts
JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_suppkey = ts.s_suppkey)
WHERE ts.rank <= 3
ORDER BY ts.nation_name, ts.total_cost DESC, os.total_revenue DESC;
