WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
), OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_custkey
), CustomerPerformance AS (
    SELECT c.c_custkey, c.c_name, COALESCE(os.total_revenue, 0) AS total_revenue, COALESCE(os.order_count, 0) AS order_count
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
), FinalReport AS (
    SELECT cd.nation_name, cp.c_name, cp.total_revenue, cp.order_count, sd.s_name AS supplier_name, sd.s_acctbal
    FROM CustomerPerformance cp
    JOIN SupplierDetails sd ON cp.total_revenue > sd.s_acctbal
    JOIN nation n ON n.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_name = sd.s_name LIMIT 1)
)
SELECT fr.nation_name, fr.c_name, fr.total_revenue, fr.order_count, fr.supplier_name, fr.s_acctbal
FROM FinalReport fr
ORDER BY fr.total_revenue DESC, fr.order_count DESC
LIMIT 10;
