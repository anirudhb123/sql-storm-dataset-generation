WITH RECURSIVE HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    INNER JOIN HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
    WHERE s.s_acctbal > hvs.s_acctbal
),
FilteredLines AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, l.l_discount,
           l.l_returnflag, l.l_linestatus,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.15
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(fl.l_extendedprice * (1 - fl.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN FilteredLines fl ON o.o_orderkey = fl.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierPerformance AS (
    SELECT ps.ps_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    INNER JOIN HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
    GROUP BY ps.ps_suppkey
)
SELECT n.n_name, r.r_name, SUM(os.total_revenue) AS total_revenue,
       COALESCE(SUM(sp.part_count), 0) AS active_part_count,
       MAX(sp.total_supply_cost) AS max_supply_cost
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey 
                                                FROM orders o 
                                                WHERE o.o_orderstatus IN ('F', 'O'))
LEFT JOIN SupplierPerformance sp ON n.n_nationkey = sp.ps_suppkey
GROUP BY n.n_name, r.r_name
HAVING SUM(os.total_revenue) IS NOT NULL
ORDER BY total_revenue DESC NULLS LAST;
