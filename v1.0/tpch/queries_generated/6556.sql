WITH RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
),
SupplierStats AS (
    SELECT s.s_nationkey, SUM(s.s_acctbal) AS total_acctbal, COUNT(s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
OrderStats AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_order_value, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT rs.r_name, rs.nation_count, ss.total_acctbal, ss.supplier_count, ss.avg_acctbal, os.total_order_value, os.order_count
FROM RegionSummary rs
LEFT JOIN SupplierStats ss ON ss.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = rs.r_name))
LEFT JOIN OrderStats os ON os.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = rs.r_name)))
ORDER BY rs.r_name, ss.total_acctbal DESC;
