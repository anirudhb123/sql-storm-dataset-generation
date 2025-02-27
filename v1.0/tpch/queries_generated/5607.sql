WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, s.s_acctbal, COUNT(ps.ps_partkey) AS parts_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT s.*, DENSE_RANK() OVER (ORDER BY s.account_balance DESC) AS rank
    FROM SupplierDetails s
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' -- Filter for recent orders
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT ts.nation_name, ts.s_name, ts.acctbal, ro.total_revenue
FROM TopSuppliers ts
JOIN RecentOrders ro ON ts.s_suppkey = ro.o_custkey 
WHERE ts.rank <= 5
ORDER BY total_revenue DESC, ts.acctbal DESC;
