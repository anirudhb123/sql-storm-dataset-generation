WITH SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sr.nation_name
    FROM SupplierRank sr
    JOIN supplier s ON sr.s_suppkey = s.s_suppkey
    WHERE sr.rank <= 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, l.l_studentkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT ts.s_name, ts.nation_name, os.o_orderkey, os.total_revenue, os.total_customers
FROM TopSuppliers ts
JOIN OrderSummary os ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
    (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey))
ORDER BY os.total_revenue DESC, ts.nation_name, ts.s_name;
