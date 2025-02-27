WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT n_name, s_suppkey, s_name, total_supply_cost,
           RANK() OVER (PARTITION BY n_name ORDER BY total_supply_cost DESC) AS rnk
    FROM NationSupplier
),
AggregatedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
FinalReport AS (
    SELECT ts.n_name, ts.s_name, ts.total_supply_cost, ao.total_revenue, ao.unique_customers
    FROM TopSuppliers ts
    JOIN AggregatedOrders ao ON ts.n_name = (
        SELECT n.n_name
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey = ts.s_suppkey
    )
    WHERE ts.rnk <= 5
)
SELECT n_name, s_name, total_supply_cost, total_revenue, unique_customers
FROM FinalReport
ORDER BY n_name, total_supply_cost DESC;
