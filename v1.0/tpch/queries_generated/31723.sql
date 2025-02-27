WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplierAvailability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)

SELECT p.p_name,
       s.s_name,
       total_avail_qty,
       os.total_revenue,
       ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY os.total_revenue DESC) AS revenue_rank
FROM part p
LEFT JOIN PartSupplierAvailability psa ON p.p_partkey = psa.ps_partkey
LEFT JOIN SupplierHierarchy s ON psa.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE (psa.total_avail_qty IS NOT NULL OR os.total_revenue IS NOT NULL)
  AND (s.s_acctbal IS NOT NULL OR p.p_retailprice > 100.00)
ORDER BY p.p_type, revenue_rank;
