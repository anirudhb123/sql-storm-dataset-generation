WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
    )
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT rf.s_name AS supplier_name, fc.c_name AS customer_name, os.total_revenue
FROM RankedSuppliers rf
JOIN FilteredCustomers fc ON rf.s_acctbal > fc.c_acctbal
JOIN OrderSummary os ON os.total_revenue > (
    SELECT AVG(total_revenue)
    FROM OrderSummary
)
ORDER BY os.total_revenue DESC
LIMIT 10;
