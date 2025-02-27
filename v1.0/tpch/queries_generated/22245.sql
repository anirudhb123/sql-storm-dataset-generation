WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 0.9, depth + 1
    FROM supplier s
    JOIN RecursiveSupplier r ON r.s_suppkey = s.s_suppkey
    WHERE depth < 3
), PartAggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
), FinalReport AS (
    SELECT p.p_partkey, p.p_name, COALESCE(pa.total_availqty, 0) AS total_availqty,
           COALESCE(pa.avg_supplycost, 0) AS avg_supplycost,
           COALESCE(os.total_revenue, 0) AS total_revenue,
           rs.s_acctbal AS supplier_balance,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY rs.s_acctbal DESC) AS supplier_rank
    FROM part p
    LEFT JOIN PartAggregation pa ON p.p_partkey = pa.ps_partkey
    LEFT JOIN OrderSummary os ON p.p_partkey = os.o_orderkey
    LEFT JOIN RecursiveSupplier rs ON rs.s_acctbal > 1000
)
SELECT f.p_partkey, f.p_name, f.total_availqty, f.avg_supplycost, f.total_revenue, f.supplier_balance
FROM FinalReport f
WHERE f.total_revenue > (SELECT AVG(total_revenue) FROM FinalReport) 
AND f.supplier_rank <= 5
ORDER BY f.total_revenue DESC
LIMIT 10;
