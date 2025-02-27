WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name as nation, 
           SUM(ps.ps_availqty) AS total_available_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.nation, s.total_available_qty, s.total_supply_cost
    FROM RankedSuppliers s
    WHERE s.rank <= 3
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ts.nation, ts.s_name AS supplier_name, 
       od.o_orderkey, od.o_orderdate, od.revenue
FROM TopSuppliers ts
JOIN OrderDetails od ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p
        WHERE p.p_retailprice > 100
    )
)
ORDER BY ts.nation, od.revenue DESC;
