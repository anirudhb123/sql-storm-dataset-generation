WITH NationStatistics AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
), PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ns.n_name, ns.supplier_count, ns.total_acctbal, ps.p_name, ps.total_cost, od.o_orderdate, od.revenue
FROM NationStatistics ns
JOIN PartSupplier ps ON ns.supplier_count > 1
JOIN OrderDetails od ON od.revenue > 50000
WHERE ns.total_acctbal > 100000.00
ORDER BY ns.n_name, ps.total_cost DESC, od.revenue DESC
LIMIT 100;
