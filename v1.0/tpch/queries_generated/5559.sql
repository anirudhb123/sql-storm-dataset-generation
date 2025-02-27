WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sc.total_cost
    FROM SupplierCosts sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    ORDER BY sc.total_cost DESC
    LIMIT 10
),
OrderSummaries AS (
    SELECT co.total_revenue, co.o_orderdate
    FROM CustomerOrders co
    JOIN TopSuppliers ts ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = ts.s_suppkey))
    WHERE co.o_orderdate >= '2023-01-01' AND co.o_orderdate < '2023-12-31'
)
SELECT AVG(os.total_revenue) AS avg_revenue, COUNT(os.o_orderdate) AS total_orders
FROM OrderSummaries os
WHERE os.total_revenue > (SELECT AVG(total_revenue) FROM CustomerOrders);
