WITH RankedSuppliers AS (
    SELECT ps_partkey, s_name, s_acctbal, RANK() OVER (PARTITION BY ps_partkey ORDER BY s_acctbal DESC) AS SupplierRank
    FROM partsupp
    JOIN supplier ON ps_suppkey = s_suppkey
    WHERE s_acctbal > 50000
), HighValueOrders AS (
    SELECT o_orderkey, o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS total_value
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY o_orderkey, o_custkey
    HAVING total_value > 100000
), CustomerRegions AS (
    SELECT c.c_custkey, n.n_nationkey, r.r_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), PartDetails AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), PartAnalysis AS (
    SELECT pd.p_partkey, pd.p_name, pd.supplier_count, AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM PartDetails pd
    LEFT JOIN RankedSuppliers rs ON pd.p_partkey = rs.ps_partkey
    LEFT JOIN supplier s ON rs.ps_suppkey = s.s_suppkey
    GROUP BY pd.p_partkey, pd.p_name, pd.supplier_count
)
SELECT cr.r_regionkey, SUM(hao.total_value) AS total_order_value, pa.supplier_count, pa.avg_supplier_acctbal
FROM HighValueOrders hao
JOIN CustomerRegions cr ON hao.o_custkey = cr.c_custkey
JOIN PartAnalysis pa ON hao.o_orderkey = pa.p_partkey
GROUP BY cr.r_regionkey, pa.supplier_count, pa.avg_supplier_acctbal
ORDER BY total_order_value DESC, pa.avg_supplier_acctbal DESC;
