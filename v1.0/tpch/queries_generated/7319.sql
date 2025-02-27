WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name as nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT *, RANK() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS rank
    FROM RankedSuppliers
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, COUNT(l.l_orderkey) AS line_item_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT R.nation_name, T.s_name, T.total_supply_cost, O.o_orderkey, O.o_orderdate, O.line_item_count, O.total_revenue
FROM TopSuppliers T
JOIN nation R ON T.nation_name = R.n_name
JOIN OrderSummary O ON R.r_regionkey = (
    SELECT r_regionkey FROM region WHERE r_name = 'EUROPE'
) 
WHERE T.rank <= 5
ORDER BY R.nation_name, T.total_supply_cost DESC, O.total_revenue DESC;
